This smart contract, **NexusIntentForge**, pioneers a decentralized, AI-augmented intent-matching and arbitration protocol. Users articulate high-level desired outcomes ("Intents") rather than explicit transaction steps. Network "Solvers" (who might be AI-driven bots) compete to propose and fulfill these intents. AI oracles (simulated here) can assist in interpreting complex intent descriptions and scoring solver proposals for quality and efficiency. A decentralized arbitration system, involving "Arbitrators" who stake tokens, resolves disputes that arise from intent fulfillment. The protocol incorporates staking, reputation systems, multi-party escrow, slashing mechanisms, and a governance framework.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Placeholder for an external AI Oracle interface (e.g., Chainlink)
// In a real implementation, this would involve Chainlink's VRF or Any API for external computations.
interface IAIOracle {
    // Requests data from the AI oracle. _jobId would specify the AI task (e.g., intent parsing, proposal scoring).
    function requestData(bytes32 _jobId, bytes calldata _payload) external returns (bytes32 requestId);
    // The oracle would then call back into this contract's 'fulfillAI...' functions.
}

/**
 * @title NexusIntentForge
 * @dev A decentralized AI-powered intent-matching and arbitration protocol.
 *      Users submit high-level "Intents" (desired outcomes). "Solvers" propose and fulfill these intents.
 *      AI Oracles (simulated) assist in intent interpretation and proposal scoring.
 *      A decentralized arbitration system resolves disputes.
 *      Features include staking, reputation, multi-party escrow, slashing mechanisms, and DAO governance (via Ownable placeholder).
 *
 * Outline:
 * 1.  Enums, Structs & State Variables: Core data structures for intents, solvers, arbitrators, etc.
 * 2.  Events: Log important actions and state changes for off-chain monitoring.
 * 3.  Modifiers: Access control and state-based checks to ensure proper execution flow.
 * 4.  Constructor: Initializes the protocol with essential parameters.
 * 5.  I. Core Intent Management: Functions for users to submit, fund, and cancel intents, and for solvers to propose, execute, and mark fulfillments.
 * 6.  II. Solver & Arbitrator Management: Functions for participants to register, update profiles, stake collateral, and deregister from the network.
 * 7.  III. AI Oracle Integration (Simulated): Functions to interact with external AI services for advanced intent interpretation and objective proposal scoring.
 * 8.  IV. Dispute Resolution: Functions to initiate disputes, for arbitrators to cast votes, and for the system to resolve disputes by applying consequences.
 * 9.  V. Protocol Governance & Maintenance: Functions for contract owner/DAO to configure protocol parameters, manage fees, and implement emergency controls.
 */
contract NexusIntentForge is Ownable, Pausable, ReentrancyGuard {

    /* ==================================================================== */
    /*                                ENUMS & STRUCTS                      */
    /* ==================================================================== */

    // States an intent can be in throughout its lifecycle.
    enum IntentState {
        Pending,        // Intent submitted, awaiting proposals from solvers.
        Proposing,      // Proposals received, user is reviewing or AI is scoring.
        Accepted,       // User accepted a proposal, awaiting solver fulfillment.
        Executing,      // Solver is in the process of fulfilling the intent.
        Fulfilled,      // Intent successfully completed by solver and confirmed by user/system.
        Disputed,       // Intent is currently under dispute resolution.
        Cancelled,      // User cancelled the intent before fulfillment.
        Expired,        // Intent deadline passed without fulfillment or cancellation.
        Reverted        // Intent execution failed or was found faulty via dispute.
    }

    // States a dispute can be in during its resolution process.
    enum DisputeState {
        Pending,        // Dispute initiated, arbitrators being selected.
        Voting,         // Arbitrators are actively casting their votes.
        Resolved        // Dispute concluded, consequences (slashing/rewards) applied.
    }

    // Represents a user's high-level desired outcome.
    struct UserIntent {
        uint256 id;
        address user;
        string description;          // High-level human-readable description of the intent (e.g., "swap USDC for max ETH").
        address targetToken;         // The token the user expects to receive as the intent's outcome.
        uint256 targetAmount;        // The desired amount of targetToken.
        uint256 valueLocked;         // Total value of tokens locked by the user for this intent.
        address[] lockedTokens;      // List of unique ERC20 tokens locked for this intent.
        mapping(address => uint256) lockedTokenAmounts; // Specific amounts of each locked token.
        uint256 deadline;            // Timestamp by which the intent must be fulfilled.
        uint256 maxGasCost;          // Maximum gas user is willing to pay for the execution.
        string preferencesHash;      // IPFS hash or similar for detailed user preferences/constraints.
        address acceptedSolver;      // Address of the solver whose proposal was accepted.
        uint256 acceptedProposalId;  // ID of the accepted proposal.
        IntentState state;
        uint256 disputeId;           // ID of the active dispute (0 if none).
        uint256 creationTime;
    }

    // Represents a solver's proposed strategy to fulfill an intent.
    struct SolverProposal {
        uint256 id;
        uint256 intentId;
        address solver;
        bytes proposalData;          // Encoded data describing the fulfillment strategy (e.g., calldata for a flash loan, swap path).
        uint256 estimatedCost;       // Total estimated cost for fulfillment (including solver fees, transaction costs).
        uint256 estimatedTime;       // Estimated time to completion in seconds.
        uint256 aiScore;             // AI-driven score reflecting the proposal's quality/efficiency.
        string reasonHash;           // IPFS hash for AI scoring reason/explanation.
        uint256 submissionTime;
    }

    // Information about a registered solver.
    struct Solver {
        string profileUri;           // IPFS hash or URL to solver's public profile/capabilities.
        uint256 stake;               // Collateral staked by the solver (in native token, e.g., ETH).
        uint256 reputation;          // Reputation score, influenced by successful fulfillments and dispute outcomes.
        uint256 lastActivityTime;    // Last time the solver interacted with the protocol.
        bool registered;
    }

    // Information about a registered arbitrator.
    struct Arbitrator {
        string profileUri;           // IPFS hash or URL to arbitrator's public profile/credentials.
        uint256 stake;               // Collateral staked by the arbitrator (in native token, e.g., ETH).
        uint256 disputesResolved;    // Count of disputes resolved correctly.
        uint256 reputation;          // Arbitrator reputation score.
        bool registered;
    }

    // Details of an ongoing or resolved dispute.
    struct Dispute {
        uint256 id;
        uint256 intentId;
        address initiator;
        string reasonHash;           // IPFS hash for detailed dispute reason/evidence.
        address[] activeArbitrators; // Arbitrators selected for this specific dispute.
        mapping(address => bool) arbitratorVoted; // Tracks which arbitrator has voted.
        mapping(address => bool) arbitratorVerdict; // True if arbitrator votes solver liable, false otherwise.
        uint256 votesForSolverLiable;
        uint256 votesAgainstSolverLiable;
        bool isResolved;             // True once the dispute has concluded.
        bool solverFoundLiable;      // Final verdict: true if solver was found responsible for fault.
        DisputeState state;
        uint256 creationTime;
        uint256 resolutionTime;
    }

    /* ==================================================================== */
    /*                             STATE VARIABLES                         */
    /* ==================================================================== */

    uint256 public nextIntentId = 1;
    mapping(uint256 => UserIntent) public intents;
    mapping(uint256 => mapping(uint256 => SolverProposal)) public intentProposals; // intentId => proposalId => SolverProposal
    mapping(uint256 => uint256) public nextProposalId; // Tracks the next available proposal ID for each intent.

    mapping(address => Solver) public solvers;
    address[] public registeredSolvers; // Array to easily iterate or select from all registered solvers.

    uint256 public nextDisputeId = 1;
    mapping(uint256 => Dispute) public disputes;
    mapping(address => Arbitrator) public arbitrators;
    address[] public registeredArbitrators; // Array to easily iterate or select from all registered arbitrators.

    // Protocol Parameters (configurable by DAO/Owner)
    uint256 public minSolverStake;                // Minimum ETH required for a solver to stake.
    uint256 public minArbitratorStake;            // Minimum ETH required for an arbitrator to stake.
    uint256 public protocolFeeBasisPoints;        // Protocol fee percentage (e.g., 500 = 5%).
    address public protocolTreasury;              // Address where protocol fees are collected.
    uint256 public disputeArbitratorCount;        // Number of arbitrators selected for each dispute.
    uint256 public disputeVotingPeriod;           // Duration in seconds for arbitrators to cast votes.

    address public aiIntentInterpretationOracle; // Address of the AI oracle for intent parsing.
    address public aiProposalScoringOracle;      // Address of the AI oracle for proposal scoring.
    bytes32 public aiInterpretationJobId;       // Chainlink Job ID for intent interpretation.
    bytes32 public aiScoringJobId;              // Chainlink Job ID for proposal scoring.

    // Balances for protocol fees and arbitrator rewards (in native token for simplicity).
    mapping(address => uint256) public protocolFeeBalances;

    /* ==================================================================== */
    /*                                EVENTS                               */
    /* ==================================================================== */

    event IntentSubmitted(uint256 indexed intentId, address indexed user, string description, uint256 deadline);
    event IntentFunded(uint256 indexed intentId, address indexed funder, address token, uint256 amount);
    event IntentCancelled(uint256 indexed intentId, address indexed user);
    event IntentExpired(uint256 indexed intentId);
    event ProposalSubmitted(uint256 indexed intentId, uint256 indexed proposalId, address indexed solver, uint256 estimatedCost);
    event ProposalAccepted(uint256 indexed intentId, uint256 indexed proposalId, address indexed user, address indexed solver);
    event IntentFulfilled(uint256 indexed intentId, address indexed solver, uint256 actualCost);
    event IntentReverted(uint256 indexed intentId, address indexed solver, string reason);
    event FundsWithdrawn(uint256 indexed intentId, address indexed recipient, address token, uint256 amount);

    event SolverRegistered(address indexed solver, uint256 stake);
    event SolverDeregistered(address indexed solver);
    event SolverReputationUpdated(address indexed solver, uint256 newReputation);

    event ArbitratorRegistered(address indexed arbitrator, uint256 stake);
    event ArbitratorDeregistered(address indexed arbitrator);
    event ArbitratorReputationUpdated(address indexed arbitrator, uint256 newReputation);

    event DisputeInitiated(uint256 indexed disputeId, uint256 indexed intentId, address indexed initiator);
    event ArbitratorVoted(uint256 indexed disputeId, address indexed arbitrator, bool isSolverLiable);
    event DisputeResolved(uint256 indexed disputeId, uint256 indexed intentId, bool solverFoundLiable);
    event ArbitratorRewardClaimed(uint256 indexed disputeId, address indexed arbitrator, uint256 rewardAmount);

    event AIInterpretationRequested(uint256 indexed intentId, bytes32 indexed requestId);
    event AIInterpretationFulfilled(uint256 indexed intentId, bytes32 indexed requestId, string interpretedDataHash);
    event AIScoringRequested(uint256 indexed intentId, uint256 indexed proposalId, bytes32 indexed requestId);
    event AIScoringFulfilled(uint256 indexed intentId, uint256 indexed proposalId, bytes32 indexed requestId, uint256 score);

    event ProtocolParameterUpdated(bytes32 indexed paramName, uint256 newValue);
    event AIOracleAddressesSet(address interpretationOracle, address scoringOracle);
    event AIOracleJobIdsSet(bytes32 interpretationJobId, bytes32 scoringJobId);
    event ProtocolFeesCollected(address indexed treasury, uint256 amount);
    event ProtocolFeesWithdrawn(address indexed recipient, uint256 amount);

    /* ==================================================================== */
    /*                                MODIFIERS                            */
    /* ==================================================================== */

    modifier onlySolver() {
        require(solvers[msg.sender].registered, "Caller is not a registered solver");
        _;
    }

    modifier onlyArbitrator() {
        require(arbitrators[msg.sender].registered, "Caller is not a registered arbitrator");
        _;
    }

    modifier onlyIntentOwner(uint256 _intentId) {
        require(intents[_intentId].user == msg.sender, "Only intent owner can perform this action");
        _;
    }

    // Placeholder modifier for DAO governance. In a real system, this would point to a DAO contract.
    modifier onlyOwnerOrDAO() {
        require(owner() == msg.sender, "Only owner or DAO can call this function");
        _;
    }

    /* ==================================================================== */
    /*                              CONSTRUCTOR                            */
    /* ==================================================================== */

    constructor(
        uint256 _minSolverStake,
        uint256 _minArbitratorStake,
        uint256 _protocolFeeBasisPoints,
        address _protocolTreasury,
        uint256 _disputeArbitratorCount,
        uint256 _disputeVotingPeriod,
        address _aiIntentInterpretationOracle,
        address _aiProposalScoringOracle,
        bytes32 _aiInterpretationJobId,
        bytes32 _aiScoringJobId
    ) Ownable(msg.sender) {
        require(_protocolFeeBasisPoints <= 10000, "Fee basis points cannot exceed 100%");
        require(_protocolTreasury != address(0), "Treasury address cannot be zero");
        require(_disputeArbitratorCount > 0, "Dispute arbitrator count must be greater than zero");

        minSolverStake = _minSolverStake;
        minArbitratorStake = _minArbitratorStake;
        protocolFeeBasisPoints = _protocolFeeBasisPoints;
        protocolTreasury = _protocolTreasury;
        disputeArbitratorCount = _disputeArbitratorCount;
        disputeVotingPeriod = _disputeVotingPeriod;

        aiIntentInterpretationOracle = _aiIntentInterpretationOracle;
        aiProposalScoringOracle = _aiProposalScoringOracle;
        aiInterpretationJobId = _aiInterpretationJobId;
        aiScoringJobId = _aiScoringJobId;
    }

    /* ==================================================================== */
    /*                         I. CORE INTENT MANAGEMENT                   */
    /* ==================================================================== */

    /**
     * @dev Submits a new user intent to the protocol. The user expresses a desired outcome.
     * @param _description High-level description of the desired outcome (e.g., "swap 100 USDC for most ETH").
     * @param _targetToken The address of the token the user expects to receive.
     * @param _targetAmount The desired amount of the target token.
     * @param _deadline Timestamp by which the intent must be fulfilled.
     * @param _maxGasCost Max gas user is willing to pay for the execution (in ETH wei or equivalent).
     * @param _prefsHash IPFS hash or similar for detailed user preferences/constraints (e.g., specific DEXes, price slippage).
     * @return intentId The ID of the newly created intent.
     */
    function submitUserIntent(
        string calldata _description,
        address _targetToken,
        uint256 _targetAmount,
        uint256 _deadline,
        uint256 _maxGasCost,
        string calldata _prefsHash
    ) external whenNotPaused nonReentrant returns (uint256 intentId) {
        require(_deadline > block.timestamp, "Intent deadline must be in the future");
        require(_targetToken != address(0), "Target token cannot be zero address");
        require(_targetAmount > 0, "Target amount must be greater than zero");

        intentId = nextIntentId++;
        UserIntent storage newIntent = intents[intentId];
        newIntent.id = intentId;
        newIntent.user = msg.sender;
        newIntent.description = _description;
        newIntent.targetToken = _targetToken;
        newIntent.targetAmount = _targetAmount;
        newIntent.deadline = _deadline;
        newIntent.maxGasCost = _maxGasCost;
        newIntent.preferencesHash = _prefsHash;
        newIntent.state = IntentState.Pending;
        newIntent.creationTime = block.timestamp;

        // Optionally, an off-chain keeper or the DAO might trigger AI interpretation here.
        // For example: requestAIIntentInterpretation(intentId);

        emit IntentSubmitted(intentId, msg.sender, _description, _deadline);
        return intentId;
    }

    /**
     * @dev Funds a specific intent with required tokens. Tokens are transferred from the user to the contract's escrow.
     *      This could be input tokens for a swap, or collateral for solver fees/gas.
     * @param _intentId The ID of the intent to fund.
     * @param _token The address of the ERC20 token to fund with.
     * @param _amount The amount of token to transfer.
     */
    function fundUserIntent(
        uint256 _intentId,
        address _token,
        uint256 _amount
    ) external whenNotPaused nonReentrant onlyIntentOwner(_intentId) {
        UserIntent storage intent = intents[_intentId];
        require(intent.state == IntentState.Pending || intent.state == IntentState.Proposing, "Intent is not in a fundable state");
        require(block.timestamp < intent.deadline, "Cannot fund an expired intent");
        require(_amount > 0, "Amount must be greater than zero");
        require(_token != address(0), "Token address cannot be zero");

        IERC20(_token).transferFrom(msg.sender, address(this), _amount);

        // Add to locked tokens for this intent, track specific amounts.
        bool tokenAlreadyLocked = false;
        for (uint256 i = 0; i < intent.lockedTokens.length; i++) {
            if (intent.lockedTokens[i] == _token) {
                tokenAlreadyLocked = true;
                break;
            }
        }
        if (!tokenAlreadyLocked) {
            intent.lockedTokens.push(_token);
        }
        intent.lockedTokenAmounts[_token] += _amount;
        intent.valueLocked += _amount; // Simplified sum, might need currency conversion in a real scenario.

        emit IntentFunded(_intentId, msg.sender, _token, _amount);
    }

    /**
     * @dev Allows the user to cancel their intent if it hasn't been accepted, fulfilled, or is not in dispute.
     *      Funds are made available for withdrawal back to the user.
     * @param _intentId The ID of the intent to cancel.
     */
    function cancelUserIntent(uint256 _intentId) external whenNotPaused nonReentrant onlyIntentOwner(_intentId) {
        UserIntent storage intent = intents[_intentId];
        require(
            intent.state == IntentState.Pending || intent.state == IntentState.Proposing,
            "Intent is not in a cancellable state (accepted, executing, disputed, fulfilled, or already cancelled/expired)"
        );
        require(block.timestamp < intent.deadline, "Cannot cancel an expired intent");

        intent.state = IntentState.Cancelled;
        // Funds can be withdrawn later via `withdrawIntentFunds`.

        emit IntentCancelled(_intentId, msg.sender);
    }

    /**
     * @dev Allows a registered solver to propose a fulfillment strategy for an open intent.
     * @param _intentId The ID of the intent to propose for.
     * @param _solverAddress The address of the solver making the proposal (must be msg.sender).
     * @param _proposalData Encoded data describing the fulfillment strategy (e.g., sequence of calls).
     * @param _estimatedCost Total estimated cost for fulfillment (including solver fees and gas).
     * @param _estimatedTime Estimated time in seconds to fulfill the intent.
     * @return proposalId The ID of the newly created proposal.
     */
    function proposeIntentFulfillment(
        uint256 _intentId,
        address _solverAddress,
        bytes calldata _proposalData,
        uint256 _estimatedCost,
        uint256 _estimatedTime
    ) external whenNotPaused nonReentrant onlySolver returns (uint256 proposalId) {
        UserIntent storage intent = intents[_intentId];
        require(intent.state == IntentState.Pending || intent.state == IntentState.Proposing, "Intent not open for proposals");
        require(block.timestamp < intent.deadline, "Intent has expired");
        require(_solverAddress == msg.sender, "Proposal must be made by the registered solver");
        require(solvers[msg.sender].stake >= minSolverStake, "Solver does not meet minimum stake requirement");

        if (intent.state == IntentState.Pending) {
            intent.state = IntentState.Proposing; // Transition state once first proposal is received.
        }

        proposalId = nextProposalId[_intentId]++;
        SolverProposal storage newProposal = intentProposals[_intentId][proposalId];
        newProposal.id = proposalId;
        newProposal.intentId = _intentId;
        newProposal.solver = msg.sender;
        newProposal.proposalData = _proposalData;
        newProposal.estimatedCost = _estimatedCost;
        newProposal.estimatedTime = _estimatedTime;
        newProposal.submissionTime = block.timestamp;

        // Optionally, request AI scoring for this proposal.
        // For example: requestAIProposalScoring(_intentId, proposalId);

        emit ProposalSubmitted(_intentId, proposalId, msg.sender, _estimatedCost);
        return proposalId;
    }

    /**
     * @dev Allows the intent owner to accept one of the solver's proposals.
     *      This locks in the chosen solver and their proposed terms.
     * @param _intentId The ID of the intent.
     * @param _proposalId The ID of the proposal to accept.
     */
    function acceptIntentFulfillment(
        uint256 _intentId,
        uint256 _proposalId
    ) external whenNotPaused nonReentrant onlyIntentOwner(_intentId) {
        UserIntent storage intent = intents[_intentId];
        require(intent.state == IntentState.Proposing, "Intent is not in a proposing state");
        require(block.timestamp < intent.deadline, "Cannot accept proposal for an expired intent");

        SolverProposal storage proposal = intentProposals[_intentId][_proposalId];
        require(proposal.solver != address(0), "Proposal does not exist");
        require(solvers[proposal.solver].registered, "Accepted solver is not registered");

        intent.acceptedSolver = proposal.solver;
        intent.acceptedProposalId = _proposalId;
        intent.state = IntentState.Accepted;

        // Ensure enough funds are locked for the estimated cost of the proposal.
        // Simplified check, in reality this needs to consider specific tokens and their value.
        require(intent.valueLocked >= proposal.estimatedCost, "Insufficient funds locked for accepted proposal cost");

        emit ProposalAccepted(_intentId, _proposalId, msg.sender, proposal.solver);
    }

    /**
     * @dev Allows the accepted solver to execute the intent. This function primarily updates the intent's state
     *      to 'Executing' and signifies that the solver has begun the external fulfillment process.
     *      The actual on-chain execution (e.g., DEX swaps, bridge calls) happens externally.
     *      Success is later confirmed by `markIntentFulfilled`.
     * @param _intentId The ID of the intent.
     * @param _proposalId The ID of the proposal being executed.
     * @param _executionProof A hash or data proving the successful external execution of the intent.
     *                        (Placeholder: in a real system, this would be validated more robustly).
     */
    function executeIntentFulfillment(
        uint256 _intentId,
        uint256 _proposalId,
        bytes calldata _executionProof // A hash or data proving the successful external execution.
    ) external whenNotPaused nonReentrant onlySolver {
        UserIntent storage intent = intents[_intentId];
        require(intent.state == IntentState.Accepted, "Intent is not in accepted state");
        require(intent.acceptedSolver == msg.sender, "Only the accepted solver can initiate execution");
        require(intent.acceptedProposalId == _proposalId, "Proposal ID mismatch");
        require(block.timestamp < intent.deadline, "Intent deadline passed for execution");

        intent.state = IntentState.Executing;
        // The _executionProof is a placeholder. A robust system might use Chainlink keepers
        // to verify on-chain events or cryptographic proofs provided by the solver.

        // Funds are not transferred here; this merely signals the start of external fulfillment.
        // Actual fund distribution happens in `markIntentFulfilled`.

        // Emitting a log here for the start of execution.
        emit IntentFulfilled(_intentId, msg.sender, 0); // Cost will be in markIntentFulfilled
    }

    /**
     * @dev Allows the intent owner or a trusted system (e.g., Chainlink Keeper) to mark an intent as truly fulfilled.
     *      This triggers the final release of funds to the solver (for their services/costs) and returns
     *      any remaining locked funds to the user.
     * @param _intentId The ID of the intent to mark as fulfilled.
     */
    function markIntentFulfilled(uint256 _intentId) external whenNotPaused nonReentrant {
        UserIntent storage intent = intents[_intentId];
        require(
            intent.state == IntentState.Executing || intent.state == IntentState.Accepted, // Accepted for direct user confirmation
            "Intent is not in a fulfillable state (must be Accepted or Executing)"
        );
        require(
            intent.user == msg.sender || intent.acceptedSolver == msg.sender || owner() == msg.sender, // Allow user, solver, or DAO/owner to confirm
            "Only intent owner, accepted solver, or protocol owner can mark as fulfilled"
        );
        require(block.timestamp < intent.deadline, "Cannot fulfill an expired intent");

        SolverProposal storage proposal = intentProposals[_intentId][intent.acceptedProposalId];
        require(proposal.solver != address(0), "No accepted proposal found for this intent.");

        // Calculate protocol fees based on the estimated cost of the proposal.
        uint256 protocolFeeAmount = (proposal.estimatedCost * protocolFeeBasisPoints) / 10000;
        protocolFeeBalances[address(this)] += protocolFeeAmount; // Collect fees internally for later transfer to treasury.

        // --- Simplified fund distribution ---
        // A real system would require careful accounting of input tokens, output tokens, and native token for gas/fees.
        // For this example:
        // - `valueLocked` represents the total `ERC20` tokens (or native ETH if applicable) user deposited.
        // - `estimatedCost` is what solver is paid (reward + actual execution costs).
        // - We assume `targetToken` has been delivered to the user by the solver externally.
        // - Any remaining `valueLocked` (after solver payment and fees) is returned to the user.

        uint256 totalFundsAvailableForDistribution = intent.valueLocked;
        require(totalFundsAvailableForDistribution >= proposal.estimatedCost + protocolFeeAmount, "Insufficient locked funds for fulfillment and fees");

        // Assuming the first locked token is the primary payment token for solver and fees.
        require(intent.lockedTokens.length > 0, "No tokens locked for this intent to distribute.");
        address paymentToken = intent.lockedTokens[0]; // Simplification: assumes one primary payment token

        // 1. Pay solver for their services and costs
        IERC20(paymentToken).transfer(proposal.solver, proposal.estimatedCost);

        // 2. Update solver reputation (positive for successful fulfillment)
        solvers[proposal.solver].reputation += 10;
        emit SolverReputationUpdated(proposal.solver, solvers[proposal.solver].reputation);

        // 3. Mark intent as fulfilled
        intent.state = IntentState.Fulfilled;

        // 4. Return any remaining locked funds (after solver payment and fees) to the user.
        for (uint256 i = 0; i < intent.lockedTokens.length; i++) {
            address token = intent.lockedTokens[i];
            uint256 amountLocked = intent.lockedTokenAmounts[token];
            if (amountLocked > 0) {
                uint256 amountToReturn = amountLocked;
                // If this is the payment token, deduct what was disbursed
                if (token == paymentToken) {
                    amountToReturn = amountLocked - proposal.estimatedCost - protocolFeeAmount;
                }
                if (amountToReturn > 0) {
                    IERC20(token).transfer(intent.user, amountToReturn);
                    emit FundsWithdrawn(_intentId, intent.user, token, amountToReturn);
                }
            }
        }
        intent.valueLocked = 0; // All funds distributed or returned.

        emit IntentFulfilled(_intentId, intent.acceptedSolver, proposal.estimatedCost);
    }

    /**
     * @dev Allows the intent owner to withdraw any remaining locked funds from a cancelled or expired intent.
     * @param _intentId The ID of the intent.
     */
    function withdrawIntentFunds(uint256 _intentId) external whenNotPaused nonReentrant onlyIntentOwner(_intentId) {
        UserIntent storage intent = intents[_intentId];
        require(
            intent.state == IntentState.Cancelled ||
            intent.state == IntentState.Expired ||
            (intent.state == IntentState.Pending && block.timestamp >= intent.deadline) ||
            (intent.state == IntentState.Proposing && block.timestamp >= intent.deadline),
            "Intent is not in a state where funds can be withdrawn (must be Cancelled, Expired, or unfulfilled & past deadline)"
        );
        require(intent.valueLocked > 0, "No funds locked for this intent to withdraw");

        // If intent wasn't explicitly cancelled but passed deadline, mark as expired.
        if (block.timestamp >= intent.deadline && intent.state != IntentState.Cancelled) {
            intent.state = IntentState.Expired;
            emit IntentExpired(_intentId);
        }

        // Transfer all remaining locked tokens back to the user.
        for (uint256 i = 0; i < intent.lockedTokens.length; i++) {
            address token = intent.lockedTokens[i];
            uint256 amount = intent.lockedTokenAmounts[token];
            if (amount > 0) {
                intent.lockedTokenAmounts[token] = 0; // Clear balance for this token.
                IERC20(token).transfer(intent.user, amount);
                emit FundsWithdrawn(_intentId, intent.user, token, amount);
            }
        }
        intent.valueLocked = 0; // Clear total locked value for the intent.
    }

    /* ==================================================================== */
    /*                     II. SOLVER & ARBITRATOR MANAGEMENT              */
    /* ==================================================================== */

    /**
     * @dev Registers a new solver in the protocol by staking the minimum required tokens (ETH).
     * @param _profileUri IPFS hash or URL to solver's public profile/capabilities.
     */
    function registerSolver(string calldata _profileUri) external payable whenNotPaused nonReentrant {
        require(!solvers[msg.sender].registered, "Solver already registered");
        require(msg.value >= minSolverStake, "Insufficient stake to register as a solver");

        solvers[msg.sender].registered = true;
        solvers[msg.sender].stake = msg.value;
        solvers[msg.sender].profileUri = _profileUri;
        solvers[msg.sender].reputation = 100; // Starting reputation score.
        solvers[msg.sender].lastActivityTime = block.timestamp;
        registeredSolvers.push(msg.sender);

        emit SolverRegistered(msg.sender, msg.value);
    }

    /**
     * @dev Allows a registered solver to update their public profile URI.
     * @param _newProfileUri New IPFS hash or URL for the solver's profile.
     */
    function updateSolverProfile(string calldata _newProfileUri) external whenNotPaused onlySolver {
        solvers[msg.sender].profileUri = _newProfileUri;
        solvers[msg.sender].lastActivityTime = block.timestamp;
    }

    /**
     * @dev Allows a registered solver to deregister and withdraw their staked tokens.
     *      Requires the solver to have no active intents or disputes. A more robust
     *      system would include checks for this or a timelock.
     */
    function deregisterSolver() external whenNotPaused nonReentrant onlySolver {
        // IMPORTANT: In a production system, thorough checks would be needed here to ensure
        // the solver has no outstanding obligations (active intents, disputes, pending funds).
        // This is simplified for the example. A timelock or grace period might also be implemented.
        require(solvers[msg.sender].stake > 0, "Solver has no stake to withdraw");

        uint256 stakeAmount = solvers[msg.sender].stake;
        solvers[msg.sender].registered = false;
        solvers[msg.sender].stake = 0;

        // Remove solver from the `registeredSolvers` array. (Inefficient for very large arrays).
        for (uint256 i = 0; i < registeredSolvers.length; i++) {
            if (registeredSolvers[i] == msg.sender) {
                registeredSolvers[i] = registeredSolvers[registeredSolvers.length - 1]; // Swap with last element
                registeredSolvers.pop(); // Remove last element
                break;
            }
        }

        (bool sent, ) = msg.sender.call{value: stakeAmount}("");
        require(sent, "Failed to send stake back to solver");

        emit SolverDeregistered(msg.sender);
    }

    /**
     * @dev Retrieves the current reputation score of a specific solver.
     * @param _solver The address of the solver.
     * @return The reputation score.
     */
    function getSolverReputation(address _solver) external view returns (uint256) {
        return solvers[_solver].reputation;
    }

    /**
     * @dev Registers a new arbitrator in the protocol by staking the minimum required tokens (ETH).
     * @param _profileUri IPFS hash or URL to arbitrator's public profile/credentials.
     */
    function registerArbitrator(string calldata _profileUri) external payable whenNotPaused nonReentrant {
        require(!arbitrators[msg.sender].registered, "Arbitrator already registered");
        require(msg.value >= minArbitratorStake, "Insufficient stake to register as an arbitrator");

        arbitrators[msg.sender].registered = true;
        arbitrators[msg.sender].stake = msg.value;
        arbitrators[msg.sender].profileUri = _profileUri;
        arbitrators[msg.sender].reputation = 100; // Starting reputation score.
        registeredArbitrators.push(msg.sender);

        emit ArbitratorRegistered(msg.sender, msg.value);
    }

    /**
     * @dev Allows a registered arbitrator to update their public profile URI.
     * @param _newProfileUri New IPFS hash or URL for the arbitrator's profile.
     */
    function updateArbitratorProfile(string calldata _newProfileUri) external whenNotPaused onlyArbitrator {
        arbitrators[msg.sender].profileUri = _newProfileUri;
    }

    /**
     * @dev Allows a registered arbitrator to deregister and withdraw their staked tokens.
     *      Requires the arbitrator to have no active disputes they are participating in.
     */
    function deregisterArbitrator() external whenNotPaused nonReentrant onlyArbitrator {
        // IMPORTANT: Similar to deregisterSolver, checks for active dispute participation would be crucial.
        require(arbitrators[msg.sender].stake > 0, "Arbitrator has no stake to withdraw");

        uint256 stakeAmount = arbitrators[msg.sender].stake;
        arbitrators[msg.sender].registered = false;
        arbitrators[msg.sender].stake = 0;

        // Remove arbitrator from the `registeredArbitrators` array.
        for (uint256 i = 0; i < registeredArbitrators.length; i++) {
            if (registeredArbitrators[i] == msg.sender) {
                registeredArbitrators[i] = registeredArbitrators[registeredArbitrators.length - 1];
                registeredArbitrators.pop();
                break;
            }
        }

        (bool sent, ) = msg.sender.call{value: stakeAmount}("");
        require(sent, "Failed to send stake back to arbitrator");

        emit ArbitratorDeregistered(msg.sender);
    }

    /* ==================================================================== */
    /*                     III. AI ORACLE INTEGRATION (Simulated)          */
    /* ==================================================================== */

    /**
     * @dev (Internal/Admin/Keeper) Requests an AI oracle to interpret a complex intent description.
     *      This would typically be triggered by a Chainlink Keeper or an off-chain service monitoring new intents.
     * @param _intentId The ID of the intent to interpret.
     * @return requestId The ID of the AI oracle request.
     */
    function requestAIIntentInterpretation(uint256 _intentId) public whenNotPaused onlyOwnerOrDAO returns (bytes32 requestId) {
        require(aiIntentInterpretationOracle != address(0), "AI Interpretation Oracle not set");
        require(intents[_intentId].user != address(0), "Intent does not exist");

        // In a real Chainlink integration:
        // bytes memory payload = abi.encodePacked(_intentId, intents[_intentId].description);
        // requestId = IAIOracle(aiIntentInterpretationOracle).requestData(aiInterpretationJobId, payload);
        // For this simulation, we generate a mock requestId.
        requestId = keccak256(abi.encodePacked("AI_INTERPRET_INTENT", _intentId, block.timestamp));

        emit AIInterpretationRequested(_intentId, requestId);
        return requestId;
    }

    /**
     * @dev (Oracle callback) Fulfills an AI intent interpretation request. This function would be
     *      called by the configured AI oracle upon completing its task.
     * @param _intentId The ID of the intent that was interpreted.
     * @param _requestId The ID of the original request.
     * @param _interpretedDataHash IPFS hash or similar for the structured AI interpretation (e.g., JSON).
     * @param _cost The cost paid to the oracle for this request (if applicable).
     */
    function fulfillAIIntentInterpretation(
        uint256 _intentId,
        bytes32 _requestId,
        string calldata _interpretedDataHash,
        uint256 _cost // Cost of AI service, potentially paid in LINK or native token
    ) external whenNotPaused {
        require(msg.sender == aiIntentInterpretationOracle, "Only AI Interpretation Oracle can fulfill this request");
        UserIntent storage intent = intents[_intentId];
        require(intent.user != address(0), "Intent does not exist");

        // In a real system, the _interpretedDataHash would be used to update the intent,
        // providing more structured data for solvers. For this example, we just log it.
        // E.g., intent.interpretedDetailsHash = _interpretedDataHash;

        emit AIInterpretationFulfilled(_intentId, _requestId, _interpretedDataHash);
    }

    /**
     * @dev (Internal/Admin/Keeper) Requests an AI oracle to score a solver's proposal.
     *      Triggered typically after a proposal is submitted, to provide an objective rating.
     * @param _intentId The ID of the intent.
     * @param _proposalId The ID of the proposal to score.
     * @return requestId The ID of the AI oracle request.
     */
    function requestAIProposalScoring(uint256 _intentId, uint256 _proposalId) public whenNotPaused onlyOwnerOrDAO returns (bytes32 requestId) {
        require(aiProposalScoringOracle != address(0), "AI Proposal Scoring Oracle not set");
        require(intents[_intentId].user != address(0), "Intent does not exist");
        require(intentProposals[_intentId][_proposalId].solver != address(0), "Proposal does not exist");

        // In a real Chainlink integration:
        // bytes memory payload = abi.encodePacked(_intentId, _proposalId, intentProposals[_intentId][_proposalId].proposalData);
        // requestId = IAIOracle(aiProposalScoringOracle).requestData(aiScoringJobId, payload);
        // For this simulation, we generate a mock requestId.
        requestId = keccak256(abi.encodePacked("AI_SCORE_PROPOSAL", _intentId, _proposalId, block.timestamp));

        emit AIScoringRequested(_intentId, _proposalId, requestId);
        return requestId;
    }

    /**
     * @dev (Oracle callback) Fulfills an AI proposal scoring request. This function would be
     *      called by the configured AI oracle upon completing its task.
     * @param _intentId The ID of the intent.
     * @param _proposalId The ID of the proposal.
     * @param _requestId The ID of the original request.
     * @param _score The AI-generated score for the proposal (e.g., 0-100).
     * @param _reasonHash IPFS hash for the AI scoring reason/explanation.
     */
    function fulfillAIProposalScoring(
        uint256 _intentId,
        uint256 _proposalId,
        bytes32 _requestId,
        uint256 _score,
        string calldata _reasonHash
    ) external whenNotPaused {
        require(msg.sender == aiProposalScoringOracle, "Only AI Proposal Scoring Oracle can fulfill this request");
        SolverProposal storage proposal = intentProposals[_intentId][_proposalId];
        require(proposal.solver != address(0), "Proposal does not exist");

        proposal.aiScore = _score;
        proposal.reasonHash = _reasonHash; // Store the hash to explanation.

        emit AIScoringFulfilled(_intentId, _proposalId, _requestId, _score);
    }

    /* ==================================================================== */
    /*                         IV. DISPUTE RESOLUTION                      */
    /* ==================================================================== */

    /**
     * @dev Allows an intent owner or solver to initiate a dispute over an intent fulfillment.
     *      This can be called if an intent is not fulfilled correctly, or if a solver believes
     *      they were wrongly accused or their payment is withheld.
     * @param _intentId The ID of the intent under dispute.
     * @param _reasonHash IPFS hash or similar for detailed dispute reason and evidence.
     * @return disputeId The ID of the newly created dispute.
     */
    function initiateDispute(uint256 _intentId, string calldata _reasonHash) external whenNotPaused nonReentrant returns (uint256 disputeId) {
        UserIntent storage intent = intents[_intentId];
        require(intent.user != address(0), "Intent does not exist");
        require(intent.state != IntentState.Fulfilled && intent.state != IntentState.Cancelled && intent.state != IntentState.Expired, "Intent is not in a disputable state");
        require(intent.disputeId == 0, "Intent already has an active dispute");
        require(msg.sender == intent.user || msg.sender == intent.acceptedSolver, "Only intent owner or accepted solver can initiate dispute");
        require(registeredArbitrators.length >= disputeArbitratorCount, "Not enough arbitrators registered to start a dispute");

        disputeId = nextDisputeId++;
        Dispute storage newDispute = disputes[disputeId];
        newDispute.id = disputeId;
        newDispute.intentId = _intentId;
        newDispute.initiator = msg.sender;
        newDispute.reasonHash = _reasonHash;
        newDispute.state = DisputeState.Pending; // Temporarily Pending for arbitrator selection
        newDispute.creationTime = block.timestamp;

        // Select arbitrators for this dispute. (Simplified: pseudo-random selection).
        // A production system would use a robust, provably fair, and sybil-resistant mechanism (e.g., VRF, reputation-weighted selection).
        for (uint256 i = 0; i < disputeArbitratorCount; i++) {
            // Simple pseudo-random using block.timestamp and intentId for slight entropy
            address selectedArbitrator = registeredArbitrators[(block.timestamp + _intentId + i) % registeredArbitrators.length];
            newDispute.activeArbitrators.push(selectedArbitrator);
        }

        intent.state = IntentState.Disputed; // Transition intent state to disputed.
        intent.disputeId = disputeId;
        newDispute.state = DisputeState.Voting; // Immediately transition dispute state to voting.

        emit DisputeInitiated(disputeId, _intentId, msg.sender);
        return disputeId;
    }

    /**
     * @dev Allows an active arbitrator in a dispute to cast their vote.
     * @param _disputeId The ID of the dispute.
     * @param _isSolverLiable True if the arbitrator finds the solver responsible for the fault, false otherwise.
     */
    function castArbitratorVote(uint256 _disputeId, bool _isSolverLiable) external whenNotPaused nonReentrant onlyArbitrator {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.state == DisputeState.Voting, "Dispute is not in voting state");
        require(block.timestamp < dispute.creationTime + disputeVotingPeriod, "Voting period has ended for this dispute");

        bool isActiveArbitrator = false;
        for (uint256 i = 0; i < dispute.activeArbitrators.length; i++) {
            if (dispute.activeArbitrators[i] == msg.sender) {
                isActiveArbitrator = true;
                break;
            }
        }
        require(isActiveArbitrator, "Caller is not an active arbitrator for this dispute");
        require(!dispute.arbitratorVoted[msg.sender], "Arbitrator has already voted in this dispute");

        dispute.arbitratorVoted[msg.sender] = true;
        dispute.arbitratorVerdict[msg.sender] = _isSolverLiable;

        if (_isSolverLiable) {
            dispute.votesForSolverLiable++;
        } else {
            dispute.votesAgainstSolverLiable++;
        }

        emit ArbitratorVoted(_disputeId, msg.sender, _isSolverLiable);

        // A keeper or the last arbitrator to vote can trigger `resolveDispute`
        // once voting period ends or all votes are in.
    }

    /**
     * @dev Resolves a dispute based on arbitrator votes, applying slashing and rewards as per the verdict.
     *      Can be triggered by anyone after the voting period ends or all arbitrators have voted.
     * @param _disputeId The ID of the dispute to resolve.
     */
    function resolveDispute(uint256 _disputeId) external whenNotPaused nonReentrant {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.state == DisputeState.Voting, "Dispute is not in voting state");
        require(
            block.timestamp >= dispute.creationTime + disputeVotingPeriod ||
            (dispute.votesForSolverLiable + dispute.votesAgainstSolverLiable) == dispute.activeArbitrators.length,
            "Voting period not ended or not all arbitrators voted yet"
        );
        require(!dispute.isResolved, "Dispute already resolved");

        UserIntent storage intent = intents[dispute.intentId];
        Solver storage solver = solvers[intent.acceptedSolver];

        // Determine outcome by majority vote. Tie-breaking could be more sophisticated.
        bool solverFoundLiable = dispute.votesForSolverLiable > dispute.votesAgainstSolverLiable;
        dispute.solverFoundLiable = solverFoundLiable;
        dispute.isResolved = true;
        dispute.state = DisputeState.Resolved;
        dispute.resolutionTime = block.timestamp;

        // Apply consequences and rewards based on the verdict.
        if (solverFoundLiable) {
            // Solver is liable: Slashing solver's stake, reputation hit, user compensation.
            uint256 slashAmount = solver.stake / 10; // Example: 10% of stake
            if (slashAmount > 0) {
                solver.stake -= slashAmount;
                protocolFeeBalances[address(this)] += slashAmount; // Slashed funds go to protocol treasury or reward pool.
            }
            solver.reputation = solver.reputation > 50 ? solver.reputation - 50 : 0; // Reputation penalty
            emit SolverReputationUpdated(intent.acceptedSolver, solver.reputation);

            // Return all locked funds to the user.
            for (uint252 i = 0; i < intent.lockedTokens.length; i++) {
                address token = intent.lockedTokens[i];
                uint256 amount = intent.lockedTokenAmounts[token];
                if (amount > 0) {
                    intent.lockedTokenAmounts[token] = 0;
                    IERC20(token).transfer(intent.user, amount);
                    emit FundsWithdrawn(intent.id, intent.user, token, amount);
                }
            }
            intent.valueLocked = 0;
            intent.state = IntentState.Reverted; // Mark intent as reverted due to solver fault.
        } else {
            // Solver is NOT liable: Reward solver, reputation boost.
            solver.reputation += 20; // Reputation reward for successful defense.
            emit SolverReputationUpdated(intent.acceptedSolver, solver.reputation);

            // If the intent was in a state where fulfillment was expected (e.g., Executing),
            // it can potentially revert to 'Accepted' for the solver to try again or be explicitly cancelled without fault.
            // For simplicity, we can set it back to `Accepted` to allow `markIntentFulfilled` to be called if pending.
            if (intent.state == IntentState.Disputed) {
                 intent.state = IntentState.Accepted; // Allow solver to resume / get paid
            }
        }

        // Distribute arbitrator rewards for correct votes (simplified).
        // Rewards could come from a portion of slashed funds, or a fixed pool.
        uint256 totalCorrectVotes = 0;
        for (uint256 i = 0; i < dispute.activeArbitrators.length; i++) {
            address arbitratorAddress = dispute.activeArbitrators[i];
            if (dispute.arbitratorVoted[arbitratorAddress] && dispute.arbitratorVerdict[arbitratorAddress] == solverFoundLiable) {
                totalCorrectVotes++;
            }
        }
        
        uint256 rewardPool = 0;
        if (solverFoundLiable) {
            // If solver was liable, reward arbitrators from the slash amount
            rewardPool = solver.stake / 20; // Example: 5% of solver's initial stake (or actual slash amount).
        } else {
            // If solver was not liable, reward arbitrators from a fixed pool or protocol fees.
            rewardPool = minArbitratorStake / 10; // Example: 10% of min arbitrator stake.
        }

        uint256 rewardPerCorrectArbitrator = (totalCorrectVotes > 0) ? (rewardPool / totalCorrectVotes) : 0;

        for (uint256 i = 0; i < dispute.activeArbitrators.length; i++) {
            address arbitratorAddress = dispute.activeArbitrators[i];
            if (dispute.arbitratorVoted[arbitratorAddress]) {
                bool correctVote = (dispute.arbitratorVerdict[arbitratorAddress] == solverFoundLiable);
                if (correctVote) {
                    arbitrators[arbitratorAddress].reputation += 5;
                    arbitrators[arbitratorAddress].disputesResolved++;
                    protocolFeeBalances[arbitratorAddress] += rewardPerCorrectArbitrator; // Add to arbitrator's claimable balance.
                    emit ArbitratorReputationUpdated(arbitratorAddress, arbitrators[arbitratorAddress].reputation);
                    // Actual claim happens via claimArbitratorReward.
                } else {
                    arbitrators[arbitratorAddress].reputation = arbitrators[arbitratorAddress].reputation > 10 ? arbitrators[arbitratorAddress].reputation - 10 : 0; // Reputation penalty for incorrect vote.
                    // Option to slash incorrect arbitrators here.
                    emit ArbitratorReputationUpdated(arbitratorAddress, arbitrators[arbitratorAddress].reputation);
                }
            }
        }

        emit DisputeResolved(_disputeId, dispute.intentId, solverFoundLiable);
    }

    /**
     * @dev Allows an arbitrator to claim rewards accumulated from correctly resolved disputes.
     *      This is a general claim function for all pending rewards for the calling arbitrator.
     */
    function claimArbitratorReward() external whenNotPaused nonReentrant onlyArbitrator {
        uint256 amount = protocolFeeBalances[msg.sender];
        require(amount > 0, "No pending rewards to claim");
        
        protocolFeeBalances[msg.sender] = 0; // Clear the balance.

        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "Failed to send reward to arbitrator");

        emit ArbitratorRewardClaimed(0, msg.sender, amount); // Using 0 for disputeId as it's a general claim.
    }


    /* ==================================================================== */
    /*                     V. PROTOCOL GOVERNANCE & MAINTENANCE            */
    /* ==================================================================== */

    /**
     * @dev Allows the owner/DAO to update a specific configurable protocol parameter.
     * @param _paramName The name of the parameter to update (e.g., "minSolverStake").
     * @param _newValue The new value for the parameter.
     */
    function updateProtocolParameter(bytes32 _paramName, uint256 _newValue) external whenNotPaused onlyOwnerOrDAO {
        if (_paramName == "minSolverStake") {
            minSolverStake = _newValue;
        } else if (_paramName == "minArbitratorStake") {
            minArbitratorStake = _newValue;
        } else if (_paramName == "protocolFeeBasisPoints") {
            require(_newValue <= 10000, "Fee basis points cannot exceed 100%");
            protocolFeeBasisPoints = _newValue;
        } else if (_paramName == "disputeArbitratorCount") {
            require(_newValue > 0, "Dispute arbitrator count must be greater than zero");
            disputeArbitratorCount = _newValue;
        } else if (_paramName == "disputeVotingPeriod") {
            disputeVotingPeriod = _newValue;
        } else {
            revert("Unknown or non-configurable parameter");
        }
        emit ProtocolParameterUpdated(_paramName, _newValue);
    }

    /**
     * @dev Allows the owner/DAO to set the addresses for the AI oracle contracts.
     * @param _interpretationOracle Address of the AI oracle for intent interpretation.
     * @param _scoringOracle Address of the AI oracle for proposal scoring.
     */
    function setAIOracleAddresses(address _interpretationOracle, address _scoringOracle) external whenNotPaused onlyOwnerOrDAO {
        aiIntentInterpretationOracle = _interpretationOracle;
        aiProposalScoringOracle = _scoringOracle;
        emit AIOracleAddressesSet(_interpretationOracle, _scoringOracle);
    }

    /**
     * @dev Allows the owner/DAO to set the Chainlink Job IDs for AI oracles.
     * @param _interpretationJobId Job ID for intent interpretation requests.
     * @param _scoringJobId Job ID for proposal scoring requests.
     */
    function setAIOracleJobIds(bytes32 _interpretationJobId, bytes32 _scoringJobId) external whenNotPaused onlyOwnerOrDAO {
        aiInterpretationJobId = _interpretationJobId;
        aiScoringJobId = _scoringJobId;
        emit AIOracleJobIdsSet(_interpretationJobId, _scoringJobId);
    }

    /**
     * @dev Pauses the contract in case of emergency (e.g., critical bug, exploit).
     *      Critical functions will be blocked. Only callable by the owner/DAO.
     */
    function emergencyPause() external onlyOwnerOrDAO {
        _pause();
    }

    /**
     * @dev Unpauses the contract after an emergency has been resolved.
     *      Only callable by the owner/DAO.
     */
    function emergencyUnpause() external onlyOwnerOrDAO {
        _unpause();
    }

    /**
     * @dev Collects accumulated protocol fees (from `protocolFeeBalances[address(this)]`)
     *      and moves them to the designated protocol treasury address.
     *      Only callable by the owner/DAO.
     */
    function collectProtocolFees() external whenNotPaused onlyOwnerOrDAO {
        uint256 amount = protocolFeeBalances[address(this)];
        require(amount > 0, "No fees to collect");
        protocolFeeBalances[address(this)] = 0; // Clear internal balance.
        protocolFeeBalances[protocolTreasury] += amount; // Add to treasury's pending balance.
        emit ProtocolFeesCollected(protocolTreasury, amount);
    }

    /**
     * @dev Withdraws collected protocol fees from the treasury's balance to a specified recipient.
     *      Only callable by the owner/DAO. Assumes fees are in native token (ETH).
     * @param _recipient The address to send the fees to.
     * @param _amount The amount of fees to withdraw.
     */
    function withdrawProtocolFees(address _recipient, uint256 _amount) external whenNotPaused onlyOwnerOrDAO {
        require(_recipient != address(0), "Recipient cannot be zero address");
        require(protocolFeeBalances[protocolTreasury] >= _amount, "Insufficient fees in treasury");
        
        protocolFeeBalances[protocolTreasury] -= _amount;

        (bool sent, ) = _recipient.call{value: _amount}("");
        require(sent, "Failed to withdraw protocol fees");

        emit ProtocolFeesWithdrawn(_recipient, _amount);
    }

    /**
     * @dev Renounces ownership of the contract.
     *      Can only be called by the current owner. After renouncing, the contract will be
     *      ownerless, and no one can call functions protected by `onlyOwner` or `onlyOwnerOrDAO`.
     *      In a DAO setup, this could be used to transfer ownership to the DAO contract address.
     */
    function renounceOwnership() public override onlyOwner {
        // Consider transferring ownership to a DAO contract instead of renouncing entirely.
        super.renounceOwnership();
    }

    // Fallback function to allow the contract to receive native token (ETH)
    receive() external payable {}
}
```