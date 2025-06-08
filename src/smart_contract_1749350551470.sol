Okay, let's design a smart contract that incorporates several advanced concepts:

1.  **Decentralized Governance:** A standard base.
2.  **Dynamic Voting Power:** Based on a combination of staked tokens and a non-transferable "Influence Score".
3.  **Influence Score System:** On-chain tracking of a reputation-like score, mutable only through governance or specific protocol actions (not direct transfer).
4.  **Govern-able Parameters:** A set of arbitrary named parameters that can be changed via governance proposals ("Flux Parameters").
5.  **Conditional Proposal Execution:** Proposals can include on-chain conditions that must be met before execution is possible.
6.  **Delegation:** Users can delegate both their token stake voting power AND their influence score voting power.
7.  **Meta-Governance:** Ability to change core governance parameters (voting periods, thresholds, weights) via governance.

Let's call this contract the `QuantumFluxGovernor`. It governs protocol parameters (`fluxParameters`) where voting power is a weighted sum of staked `StabilityTokens` and non-transferable `QuantumInfluencePoints`.

---

**QuantumFluxGovernor Contract**

**Outline:**

1.  **License and Pragma**
2.  **Imports (IERC20)**
3.  **Errors**
4.  **Events**
5.  **Enums (ProposalState)**
6.  **Structs (Proposal)**
7.  **State Variables:**
    *   Core Governance Config (periods, delays, thresholds)
    *   Proposal Storage (`proposals`, `proposalCount`)
    *   Vote Storage (`votes`, `proposalVotes`)
    *   Delegation Storage (`delegates`, `delegatedVotes`) - simplified, using current state.
    *   Voting Power Config (`stabilityWeight`, `influenceWeight`)
    *   Staking Token Address
    *   Influence Point Storage (`quantumInfluencePoints`)
    *   Govern-able Parameters Storage (`fluxParameters`)
    *   Guardian/Pauser Role
    *   Snapshot tracking (minimalist - using current state for QIP, assuming staked token handles snapshots or using current balance).
8.  **Modifiers**
9.  **Constructor**
10. **Core Governance Functions:**
    *   `propose`
    *   `castVote` (`castVoteWithReason`, `castVoteBySig` - signatures for advanced)
    *   `queue`
    *   `execute`
    *   `cancel`
11. **View Functions:**
    *   `state`
    *   `getProposalDetails`
    *   `getVotingPower`
    *   `getInfluencePoints`
    *   `getFluxParameter`
    *   `getQuorumVotes`
    *   `getProposalThreshold`
    *   `getVotingPeriod`
    *   `getQueuePeriod`
    *   `getExecutionDelay`
    *   `getStabilityWeight`
    *   `getInfluenceWeight`
    *   `getGuardian`
    *   `getStakingToken`
    *   `getLatestProposalId`
    *   `getDelegation`
    *   `hasVoted`
13. **Delegation Functions:**
    *   `delegate`
    *   `delegateBySig` (Signature concept)
14. **Influence Point Management (Guardian/Governance Only):**
    *   `awardInfluencePoints`
    *   `slashInfluencePoints`
15. **Internal/Helper Functions:**
    *   `_getVotingPower`
    *   `_setFluxParameter` (Called by execute)
    *   `_setWeights` (Called by execute)
    *   `_updateGovernanceParameter` (Called by execute)
    *   `_checkCondition` (Checks optional condition bytes)
    *   `hashProposal`
    *   `_beforeExecute` (Hook)
    *   `_afterExecute` (Hook)
16. **Governance Parameter Update Functions (Callable only by `execute`):**
    *   `setVotingPeriod`
    *   `setQueuePeriod`
    *   `setExecutionDelay`
    *   `setProposalThreshold`
    *   `setStabilityWeight`
    *   `setInfluenceWeight`
    *   `setGuardian`
    *   `setStakingToken`
17. **Placeholder/Advanced Functions (Example):**
    *   `proposeSetFluxParameter` (Helper to build proposal calldata)
    *   `proposeSetWeights` (Helper)
    *   `proposeUpdateGovernanceParameter` (Helper)
    *   `executeConditionalProposal` (Alias/wrapper for execute)
    *   `checkProposalCondition` (Public check for conditional proposals)
    *   `batchPropose` (Propose multiple actions)
    *   `batchDelegate` (Delegate to multiple addresses - concept)

**Function Summary:**

1.  `constructor`: Initializes contract with token, governance params, weights, and guardian.
2.  `propose`: Creates a new governance proposal with actions and an optional condition. Requires minimum combined voting power.
3.  `castVote`: Records a vote (For/Against/Abstain) for a proposal.
4.  `castVoteWithReason`: Records a vote with an attached reason string.
5.  `castVoteBySig`: Allows voting via an EIP-712 signature (abstracted signature validation).
6.  `queue`: Moves a successful proposal from 'Succeeded' to 'Queued'. Requires meeting quorum and success threshold.
7.  `execute`: Executes a queued proposal after the timelock expires, provided its optional condition (if any) is met.
8.  `cancel`: Cancels a proposal if it's not yet queued (callable by proposer or guardian).
9.  `state`: Returns the current state of a proposal.
10. `getProposalDetails`: Retrieves the full details of a specific proposal.
11. `getVotingPower`: Calculates and returns the current effective voting power for an address (considering delegation, stake, and influence).
12. `getInfluencePoints`: Returns the current Quantum Influence Points for an address.
13. `getFluxParameter`: Returns the value of a specific named flux parameter.
14. `getQuorumVotes`: Returns the minimum voting power required for a proposal to reach quorum.
15. `getProposalThreshold`: Returns the minimum voting power required to create a proposal.
16. `getVotingPeriod`: Returns the duration of the voting period.
17. `getQueuePeriod`: Returns the minimum time a proposal must be queued before execution is possible.
18. `getExecutionDelay`: Returns the additional delay after queuing before execution is possible.
19. `getStabilityWeight`: Returns the current weight applied to staked tokens in voting power calculation.
20. `getInfluenceWeight`: Returns the current weight applied to influence points in voting power calculation.
21. `getGuardian`: Returns the address of the current guardian.
22. `getStakingToken`: Returns the address of the staked token contract.
23. `getLatestProposalId`: Returns the ID of the most recently created proposal.
24. `getDelegation`: Returns the address the caller's voting power is currently delegated to.
25. `hasVoted`: Checks if an address has already voted on a specific proposal.
26. `delegate`: Delegates the caller's voting power to another address.
27. `delegateBySig`: Delegates voting power using an EIP-712 signature (abstracted).
28. `awardInfluencePoints`: (Callable by guardian or governance) Increases an address's Quantum Influence Points.
29. `slashInfluencePoints`: (Callable by guardian or governance) Decreases an address's Quantum Influence Points.
30. `_setFluxParameter`: Internal function called by `execute` to change a flux parameter.
31. `_setWeights`: Internal function called by `execute` to change voting power weights.
32. `_updateGovernanceParameter`: Internal helper called by `execute` to update various governance settings.
33. `setVotingPeriod`: Callable only by `execute` to update the voting period.
34. `setQueuePeriod`: Callable only by `execute` to update the queue period.
35. `setExecutionDelay`: Callable only by `execute` to update the execution delay.
36. `setProposalThreshold`: Callable only by `execute` to update the proposal threshold.
37. `setStabilityWeight`: Callable only by `execute` to update the stability weight.
38. `setInfluenceWeight`: Callable only by `execute` to update the influence weight.
39. `setGuardian`: Callable only by `execute` to update the guardian address.
40. `setStakingToken`: Callable only by `execute` to update the staking token address.
41. `_checkCondition`: Internal helper to evaluate the optional condition bytes for a proposal.
42. `hashProposal`: Helper function to compute the unique hash for a proposal.
43. `_beforeExecute`: Internal hook executed before proposal actions are called.
44. `_afterExecute`: Internal hook executed after proposal actions are called.
45. `proposeSetFluxParameter`: Convenience helper to build calldata for proposing a flux parameter change.
46. `proposeSetWeights`: Convenience helper to build calldata for proposing a weight change.
47. `proposeUpdateGovernanceParameter`: Convenience helper to build calldata for proposing changes to various governance settings.
48. `executeConditionalProposal`: Alias for `execute` emphasizing the conditional aspect.
49. `checkProposalCondition`: Public function to check the condition of a specific proposal at any time.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Note: This contract is a complex example demonstrating concepts.
// In a production environment, comprehensive testing, audits,
// and potentially a proxy pattern for upgradability would be essential.
// Snapshotting for token balance history (like Compound/OpenZeppelin Governor)
// is common but omitted here for simplicity, using current balance/QIP.
// EIP-712 signature handling for delegateBySig/castVoteBySig is abstracted.

/**
 * @title QuantumFluxGovernor
 * @dev A decentralized governance contract with dynamic voting power
 * based on staked tokens and influence points, govern-able parameters,
 * and conditional proposal execution.
 *
 * Outline:
 * - License and Pragma
 * - Imports (IERC20, SafeMath, Address, ReentrancyGuard)
 * - Errors
 * - Events
 * - Enums (ProposalState)
 * - Structs (Proposal)
 * - State Variables (Governance Config, Proposal Storage, Votes, Delegation, Weights, Tokens, Influence, Flux Params, Guardian)
 * - Modifiers
 * - Constructor
 * - Core Governance Functions (propose, castVote, castVoteWithReason, castVoteBySig, queue, execute, cancel)
 * - View Functions (state, getProposalDetails, getVotingPower, getInfluencePoints, getFluxParameter, getQuorumVotes, getProposalThreshold, getVotingPeriod, getQueuePeriod, getExecutionDelay, getStabilityWeight, getInfluenceWeight, getGuardian, getStakingToken, getLatestProposalId, getDelegation, hasVoted)
 * - Delegation Functions (delegate, delegateBySig)
 * - Influence Point Management (awardInfluencePoints, slashInfluencePoints) - Guardian/Governance Only
 * - Internal/Helper Functions (_getVotingPower, _setFluxParameter, _setWeights, _updateGovernanceParameter, _checkCondition, hashProposal, _beforeExecute, _afterExecute)
 * - Governance Parameter Update Functions (Callable only by execute)
 * - Placeholder/Advanced Functions (proposeSetFluxParameter, proposeSetWeights, proposeUpdateGovernanceParameter, executeConditionalProposal, checkProposalCondition, batchPropose, batchDelegate - concepts)
 *
 * Function Summary:
 * 1.  constructor: Initializes contract with token, governance params, weights, and guardian.
 * 2.  propose: Creates a new governance proposal. Requires minimum combined voting power.
 * 3.  castVote: Records a vote (For/Against/Abstain).
 * 4.  castVoteWithReason: Records a vote with a reason string.
 * 5.  castVoteBySig: Allows voting via an EIP-712 signature (abstracted validation).
 * 6.  queue: Moves a successful proposal to 'Queued'. Requires meeting quorum/thresholds.
 * 7.  execute: Executes a queued proposal after timelock and if its optional condition is met.
 * 8.  cancel: Cancels a proposal (proposer or guardian).
 * 9.  state: Returns the current state of a proposal.
 * 10. getProposalDetails: Retrieves full proposal details.
 * 11. getVotingPower: Calculates current effective voting power.
 * 12. getInfluencePoints: Returns an address's Influence Points.
 * 13. getFluxParameter: Returns a named flux parameter value.
 * 14. getQuorumVotes: Returns required quorum voting power.
 * 15. getProposalThreshold: Returns minimum power to propose.
 * 16. getVotingPeriod: Returns voting period duration.
 * 17. getQueuePeriod: Returns queue period duration.
 * 18. getExecutionDelay: Returns execution delay duration.
 * 19. getStabilityWeight: Returns stability token weight.
 * 20. getInfluenceWeight: Returns influence point weight.
 * 21. getGuardian: Returns guardian address.
 * 22. getStakingToken: Returns staked token address.
 * 23. getLatestProposalId: Returns ID of latest proposal.
 * 24. getDelegation: Returns current delegate for an address.
 * 25. hasVoted: Checks if an address voted on a proposal.
 * 26. delegate: Delegates voting power.
 * 27. delegateBySig: Delegates via EIP-712 signature (abstracted).
 * 28. awardInfluencePoints: (Guardian/Gov) Increases Influence Points.
 * 29. slashInfluencePoints: (Guardian/Gov) Decreases Influence Points.
 * 30. _setFluxParameter: Internal, called by execute, sets flux parameter.
 * 31. _setWeights: Internal, called by execute, sets voting weights.
 * 32. _updateGovernanceParameter: Internal, called by execute, updates gov params.
 * 33. setVotingPeriod: (Only self) Sets voting period.
 * 34. setQueuePeriod: (Only self) Sets queue period.
 * 35. setExecutionDelay: (Only self) Sets execution delay.
 * 36. setProposalThreshold: (Only self) Sets proposal threshold.
 * 37. setStabilityWeight: (Only self) Sets stability weight.
 * 38. setInfluenceWeight: (Only self) Sets influence weight.
 * 39. setGuardian: (Only self) Sets guardian address.
 * 40. setStakingToken: (Only self) Sets staking token address.
 * 41. _checkCondition: Internal helper, evaluates proposal condition.
 * 42. hashProposal: Helper, computes proposal hash.
 * 43. _beforeExecute: Internal hook before execution.
 * 44. _afterExecute: Internal hook after execution.
 * 45. proposeSetFluxParameter: Helper to build proposal calldata for flux param change.
 * 46. proposeSetWeights: Helper to build calldata for weights change.
 * 47. proposeUpdateGovernanceParameter: Helper to build calldata for gov param changes.
 * 48. executeConditionalProposal: Alias for execute.
 * 49. checkProposalCondition: Public check for proposal condition.
 */
contract QuantumFluxGovernor is ReentrancyGuard {
    using SafeMath for uint256;
    using Address for address;

    // --- Errors ---
    error QuantumFluxGovernor__InvalidState();
    error QuantumFluxGovernor__ThresholdNotMet(uint256 required, uint256 available);
    error QuantumFluxGovernor__VotingPeriodNotActive();
    error QuantumFluxGovernor__ProposalNotSucceeded();
    error QuantumFluxGovernor__ProposalNotQueued();
    error QuantumFluxGovernor__ExecutionTimelockNotMet();
    error QuantumFluxGovernor__ExecutionConditionNotMet();
    error QuantumFluxGovernor__ProposalAlreadyVoted();
    error QuantumFluxGovernor__InsufficientVotingPower();
    error QuantumFluxGovernor__Unauthorized();
    error QuantumFluxGovernor__InvalidVoteType();
    error QuantumFluxGovernor__ProposalCancelled();
    error QuantumFluxGovernor__InvalidTargetLength();
    error QuantumFluxGovernor__InvalidValueLength();
    error QuantumFluxGovernor__InvalidCalldataLength();
    error QuantumFluxGovernor__InvalidConditionFormat();
    error QuantumFluxGovernor__CannotDelegateToSelf();
    error QuantumFluxGovernor__InvalidInfluenceAmount();
    error QuantumFluxGovernor__SlashedInfluenceExceedsBalance();

    // --- Events ---
    event ProposalCreated(
        uint256 id,
        address proposer,
        address[] targets,
        uint256[] values,
        bytes[] calldatas,
        string description,
        bytes condition, // Added condition field
        uint256 startBlock,
        uint256 endBlock
    );
    event VoteCast(
        address voter,
        uint256 proposalId,
        uint8 support, // 0 = Against, 1 = For, 2 = Abstain
        uint256 weight, // Voting power used
        string reason
    );
    event ProposalQueued(uint256 proposalId, uint256 queueEndTime);
    event ProposalExecuted(uint256 proposalId);
    event ProposalCanceled(uint256 proposalId);
    event DelegateChanged(address delegator, address fromDelegate, address toDelegate);
    event DelegateVotesChanged(address delegate, uint256 previousBalance, uint256 newBalance);
    event InfluencePointsAwarded(address recipient, uint256 amount, address indexed manager);
    event InfluencePointsSlashed(address recipient, uint256 amount, address indexed manager);
    event FluxParameterChanged(bytes32 indexed name, uint256 oldValue, uint256 newValue, address indexed governor);
    event VotingWeightsChanged(uint256 oldStabilityWeight, uint256 newStabilityWeight, uint256 oldInfluenceWeight, uint256 newInfluenceWeight, address indexed governor);
    event GovernanceParameterChanged(bytes32 indexed name, uint256 oldValue, uint256 newValue, address indexed governor);

    // --- Enums ---
    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Succeeded,
        Queued,
        Expired,
        Executed
    }

    // --- Structs ---
    struct Proposal {
        uint256 id;
        address proposer;
        uint256 startBlock;
        uint256 endBlock;
        uint256 queueEndTime; // When it enters the queue + timelock
        uint256 eta; // Earliest timestamp for execution (queueEndTime + executionDelay)
        address[] targets;
        uint256[] values;
        bytes[] calldatas;
        bytes condition; // Optional condition bytes to check before execution
        bool executed;
        bool canceled;
        uint256 againstVotes;
        uint256 forVotes;
        uint256 abstainVotes;
        mapping(address => bool) hasVoted; // Tracks if an address has voted
        string description;
    }

    // --- State Variables ---
    uint256 public proposalCount;
    mapping(uint256 => Proposal) public proposals;

    uint256 public votingPeriod; // In blocks
    uint256 public queuePeriod; // Minimum seconds in queue (for timelock clarity)
    uint256 public executionDelay; // Additional seconds delay after queuing
    uint256 public proposalThreshold; // Minimum voting power to create a proposal
    uint256 public quorumDenominator = 100; // Quorum is total supply / quorumDenominator

    uint256 public stabilityWeight; // Weight for staked tokens (e.g., 1e18 for 1:1)
    uint256 public influenceWeight; // Weight for influence points (e.g., 1e18 for 1:1)

    IERC20 public immutable STAKING_TOKEN; // The token granting vote power (needs to be staked elsewhere, this contract reads balance)
    mapping(address => uint256) public quantumInfluencePoints; // Non-transferable influence score

    address public guardian; // Address with emergency cancellation/IP management rights

    // Dynamic, govern-able parameters
    mapping(bytes32 => uint256) public fluxParameters;

    // Delegation storage: Simplified, uses current balance/QIP of the delegate
    mapping(address => address) public delegates;

    // --- Modifiers ---
    modifier onlyGuardianOrSelf(address account) {
        if (msg.sender != guardian && msg.sender != account) {
            revert QuantumFluxGovernor__Unauthorized();
        }
        _;
    }

    modifier onlyGuardian() {
        if (msg.sender != guardian) {
            revert QuantumFluxGovernor__Unauthorized();
        }
        _;
    }

    modifier onlySelf() {
        if (msg.sender != address(this)) {
            revert QuantumFluxGovernor__Unauthorized();
        }
        _;
    }

    // --- Constructor ---
    constructor(
        address _stakingToken,
        uint256 _votingPeriod,
        uint256 _queuePeriod,
        uint256 _executionDelay,
        uint256 _proposalThreshold,
        uint256 _stabilityWeight,
        uint256 _influenceWeight,
        address _guardian
    ) {
        STAKING_TOKEN = IERC20(_stakingToken);
        votingPeriod = _votingPeriod;
        queuePeriod = _queuePeriod;
        executionDelay = _executionDelay;
        proposalThreshold = _proposalThreshold;
        stabilityWeight = _stabilityWeight;
        influenceWeight = _influenceWeight;
        guardian = _guardian;
    }

    // --- Core Governance Functions ---

    /**
     * @dev Creates a new governance proposal.
     * @param targets The addresses of the contracts to call.
     * @param values The ether values to send with each call.
     * @param calldatas The calldata for each call.
     * @param condition An optional bytes payload representing an on-chain condition check. If not empty, _checkCondition must return true for execution.
     * @param description The description of the proposal.
     * Requirements:
     * - Caller must have voting power >= proposalThreshold.
     * - Lengths of targets, values, and calldatas must be equal and non-zero.
     */
    function propose(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata calldatas,
        bytes calldata condition,
        string calldata description
    ) external nonReentrant returns (uint256) {
        if (targets.length == 0 || targets.length != values.length || targets.length != calldatas.length) {
            revert QuantumFluxGovernor__InvalidTargetLength(); // Covers value and calldata length too
        }

        uint256 proposerVotingPower = _getVotingPower(msg.sender);
        if (proposerVotingPower < proposalThreshold) {
            revert QuantumFluxGovernor__ThresholdNotMet(proposalThreshold, proposerVotingPower);
        }

        proposalCount++;
        uint256 proposalId = proposalCount;

        uint256 startBlock = block.number;
        uint256 endBlock = startBlock + votingPeriod;

        Proposal storage newProposal = proposals[proposalId];
        newProposal.id = proposalId;
        newProposal.proposer = msg.sender;
        newProposal.startBlock = startBlock;
        newProposal.endBlock = endBlock;
        newProposal.targets = targets;
        newProposal.values = values;
        newProposal.calldatas = calldatas;
        newProposal.condition = condition;
        newProposal.description = description;
        newProposal.executed = false;
        newProposal.canceled = false;
        newProposal.queueEndTime = 0; // Not queued yet
        newProposal.eta = 0; // No execution time yet

        emit ProposalCreated(
            proposalId,
            msg.sender,
            targets,
            values,
            calldatas,
            description,
            condition,
            startBlock,
            endBlock
        );

        return proposalId;
    }

    /**
     * @dev Casts a vote for a proposal.
     * @param proposalId The ID of the proposal to vote on.
     * @param support The type of vote (0=Against, 1=For, 2=Abstain).
     * Requirements:
     * - Proposal must be in the 'Active' state.
     * - Caller must not have already voted.
     * - Caller must have non-zero voting power.
     */
    function castVote(uint256 proposalId, uint8 support) external nonReentrant {
        castVoteWithReason(proposalId, support, "");
    }

    /**
     * @dev Casts a vote for a proposal with an optional reason.
     * @param proposalId The ID of the proposal to vote on.
     * @param support The type of vote (0=Against, 1=For, 2=Abstain).
     * @param reason An optional string explaining the vote.
     * Requirements:
     * - Proposal must be in the 'Active' state.
     * - Caller must not have already voted.
     * - Caller must have non-zero voting power.
     */
    function castVoteWithReason(uint256 proposalId, uint8 support, string calldata reason) public nonReentrant {
        ProposalState currentState = state(proposalId);
        if (currentState != ProposalState.Active) {
            revert QuantumFluxGovernor__VotingPeriodNotActive();
        }

        Proposal storage proposal = proposals[proposalId];

        if (proposal.hasVoted[msg.sender]) {
            revert QuantumFluxGovernor__ProposalAlreadyVoted();
        }

        address voter = delegates[msg.sender] == address(0) ? msg.sender : delegates[msg.sender];
        uint256 votingPower = _getVotingPower(voter);

        if (votingPower == 0) {
            revert QuantumFluxGovernor__InsufficientVotingPower();
        }

        proposal.hasVoted[msg.sender] = true; // Mark the original msg.sender as having voted

        if (support == 0) {
            proposal.againstVotes = proposal.againstVotes.add(votingPower);
        } else if (support == 1) {
            proposal.forVotes = proposal.forVotes.add(votingPower);
        } else if (support == 2) {
            proposal.abstainVotes = proposal.abstainVotes.add(votingPower);
        } else {
            revert QuantumFluxGovernor__InvalidVoteType();
        }

        emit VoteCast(voter, proposalId, support, votingPower, reason);
    }

    /**
     * @dev Casts a vote for a proposal using an EIP-712 signature.
     * @param proposalId The ID of the proposal.
     * @param support The type of vote.
     * @param reason An optional reason string.
     * @param v, r, s The signature components.
     * Note: Signature verification logic needs to be implemented or integrated (e.g., ERC-1271 for contracts).
     * This function signature is included for conceptual completeness for the 20+ function count.
     */
    function castVoteBySig(uint256 proposalId, uint8 support, string calldata reason, uint8 v, bytes32 r, bytes32 s) external {
         // @TODO: Implement EIP-712 signature verification here
         // Recover address from signature
         // Check if recovered address has not voted
         // Check if signature is valid for vote parameters (proposalId, support, reason)
         // If valid, proceed as if the recovered address called castVoteWithReason
         revert("castVoteBySig not fully implemented"); // Placeholder
         // Example call if signature were valid: castVoteWithReason(proposalId, support, reason);
    }

    /**
     * @dev Moves a successful proposal to the queued state.
     * @param proposalId The ID of the proposal.
     * Requirements:
     * - Proposal must be in the 'Succeeded' state.
     */
    function queue(uint256 proposalId) external nonReentrant {
        ProposalState currentState = state(proposalId);
        if (currentState != ProposalState.Succeeded) {
            revert QuantumFluxGovernor__ProposalNotSucceeded();
        }

        Proposal storage proposal = proposals[proposalId];
        proposal.queueEndTime = block.timestamp + queuePeriod;
        proposal.eta = proposal.queueEndTime + executionDelay;

        emit ProposalQueued(proposalId, proposal.eta);
    }

    /**
     * @dev Executes a queued proposal.
     * @param proposalId The ID of the proposal.
     * Requirements:
     * - Proposal must be in the 'Queued' state.
     * - Current timestamp must be >= the proposal's execution timestamp (eta).
     * - The optional condition bytes (if any) must evaluate to true via _checkCondition.
     */
    function execute(uint256 proposalId) external payable nonReentrant {
        Proposal storage proposal = proposals[proposalId];
        ProposalState currentState = state(proposalId);

        if (currentState != ProposalState.Queued) {
            revert QuantumFluxGovernor__ProposalNotQueued();
        }

        if (block.timestamp < proposal.eta) {
            revert QuantumFluxGovernor__ExecutionTimelockNotMet();
        }

        // Check optional condition
        if (proposal.condition.length > 0) {
            if (!_checkCondition(proposal.condition)) {
                revert QuantumFluxGovernor__ExecutionConditionNotMet();
            }
        }

        proposal.executed = true;

        _beforeExecute(proposalId);

        for (uint i = 0; i < proposal.targets.length; i++) {
            (bool success, ) = proposal.targets[i].call{value: proposal.values[i]}(proposal.calldatas[i]);
            // Decide on error handling: revert on first failure, or continue and log?
            // Reverting is safer for critical operations.
            require(success, "QuantumFluxGovernor: Execution failed");
        }

        _afterExecute(proposalId);

        emit ProposalExecuted(proposalId);
    }

    /**
     * @dev Cancels a proposal.
     * @param proposalId The ID of the proposal.
     * Requirements:
     * - Callable by the proposal's proposer or the guardian.
     * - Proposal must be in 'Pending' or 'Active' state.
     */
    function cancel(uint256 proposalId) external nonReentrant {
        Proposal storage proposal = proposals[proposalId];
        ProposalState currentState = state(proposalId);

        if (msg.sender != proposal.proposer && msg.sender != guardian) {
            revert QuantumFluxGovernor__Unauthorized();
        }

        if (currentState != ProposalState.Pending && currentState != ProposalState.Active) {
             revert QuantumFluxGovernor__InvalidState(); // Can only cancel pending or active
        }

        proposal.canceled = true;

        emit ProposalCanceled(proposalId);
    }

    // --- View Functions ---

    /**
     * @dev Returns the current state of a proposal.
     * @param proposalId The ID of the proposal.
     * @return The ProposalState enum value.
     */
    function state(uint256 proposalId) public view returns (ProposalState) {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.id == 0 && proposalId > 0) { // ProposalId 0 is default, check if it exists
             // Or maybe revert if proposalId doesn't exist? Depends on desired behavior.
             // Let's assume proposalId 0 is invalid.
             // A non-existent ID would have default struct values, likely appearing Pending/Defeated.
             // A check like `require(proposalId > 0 && proposalId <= proposalCount, "Invalid proposal ID");` could be added.
             // For simplicity, state() will report based on default values if ID is not found.
             // Let's check proposalCount to be safer.
             if (proposalId == 0 || proposalId > proposalCount) {
                // Non-existent, let's just return a sensible default or error. Default is Pending/Defeated.
                // Let's return Expired for non-existent >= 1.
                if (proposalId > 0) return ProposalState.Expired; // Non-existent behaves like expired? Or Invalid? Let's treat 0 as invalid.
             }
        }

        if (proposal.canceled) {
            return ProposalState.Canceled;
        } else if (proposal.executed) {
            return ProposalState.Executed;
        } else if (block.number < proposal.startBlock) {
            return ProposalState.Pending;
        } else if (block.number <= proposal.endBlock) {
            return ProposalState.Active;
        } else if (proposal.eta != 0) { // Proposal is queued or was queued
             if (block.timestamp < proposal.eta) {
                 return ProposalState.Queued;
             } else { // Timelock met for queued proposal
                  // Check if successful and queued, but not executed and timelock met.
                  // It could be Expired if execute wasn't called, or Defeated if conditions weren't met,
                  // or just waiting execution. Let's differentiate Expired by timelock met but not executed.
                  // It could also be Succeeded *before* queuing.
                  // Let's refine states: Pending -> Active -> Succeeded/Defeated -> Queued -> Expired/Executed.
                  // If it's queued and eta is passed and not executed, it's essentially 'ready to execute' but state remains Queued until executed.
                  // If it was Succeeded but queue wasn't called, and endBlock passed, it becomes Expired.
                  // If it was Queued, eta passed, condition failed, it should maybe transition? No, condition check is only on execute.
                  // So, if endBlock passed:
                  // - If Succeeded but not Queued: Expired.
                  // - If Queued and eta passed and not executed: Queued (awaiting execution).
                 if (proposal.queueEndTime == 0) { // Wasn't queued
                      // Now check if it succeeded based on votes
                      uint256 quorumVotes = getQuorumVotes();
                      uint256 totalVotes = proposal.forVotes.add(proposal.againstVotes).add(proposal.abstainVotes);
                      if (totalVotes >= quorumVotes && proposal.forVotes > proposal.againstVotes) {
                          return ProposalState.Succeeded;
                      } else {
                          return ProposalState.Defeated;
                      }
                 } else { // Was Queued, and eta passed
                     return ProposalState.Queued; // Still queued, but executable (if condition met on call)
                 }
             }
        } else { // endBlock passed, and not queued
             // Check if it succeeded based on votes
             uint256 quorumVotes = getQuorumVotes();
             uint256 totalVotes = proposal.forVotes.add(proposal.againstVotes).add(proposal.abstainVotes);
             if (totalVotes >= quorumVotes && proposal.forVotes > proposal.againstVotes) {
                 return ProposalState.Succeeded; // Succeeded but not queued before expiration
             } else {
                 return ProposalState.Defeated; // Defeated by votes
             }
        }
    }

    /**
     * @dev Retrieves the full details of a specific proposal.
     * @param proposalId The ID of the proposal.
     * @return A tuple containing all proposal fields.
     */
    function getProposalDetails(uint256 proposalId)
        public
        view
        returns (
            uint256 id,
            address proposer,
            uint256 startBlock,
            uint256 endBlock,
            uint256 queueEndTime,
            uint256 eta,
            address[] memory targets,
            uint256[] memory values,
            bytes[] memory calldatas,
            bytes memory condition,
            bool executed,
            bool canceled,
            uint256 againstVotes,
            uint256 forVotes,
            uint256 abstainVotes,
            string memory description
        )
    {
        Proposal storage proposal = proposals[proposalId];
        return (
            proposal.id,
            proposal.proposer,
            proposal.startBlock,
            proposal.endBlock,
            proposal.queueEndTime,
            proposal.eta,
            proposal.targets,
            proposal.values,
            proposal.calldatas,
            proposal.condition,
            proposal.executed,
            proposal.canceled,
            proposal.againstVotes,
            proposal.forVotes,
            proposal.abstainVotes,
            proposal.description
        );
    }

    /**
     * @dev Calculates the effective voting power for an address at the current time.
     * Considers delegation, staked tokens balance, and influence points.
     * @param account The address to check.
     * @return The calculated voting power.
     */
    function getVotingPower(address account) public view returns (uint256) {
        address delegatee = delegates[account] == address(0) ? account : delegates[account];
        return _getVotingPower(delegatee);
    }

     /**
     * @dev Internal helper to calculate voting power based on delegatee's stake and influence.
     * @param delegatee The address whose power is being calculated (either the user or their delegate).
     * @return The calculated voting power.
     */
    function _getVotingPower(address delegatee) internal view returns (uint256) {
         uint256 stakedBalance = STAKING_TOKEN.balanceOf(delegatee);
         uint256 influence = quantumInfluencePoints[delegatee];

         // Avoid overflow: calculate weighted components separately then add
         uint256 stakeComponent = stakedBalance.mul(stabilityWeight);
         uint256 influenceComponent = influence.mul(influenceWeight);

         // Assuming weights and token amounts are scaled appropriately (e.g., using 18 decimals)
         // to avoid loss of precision or massive numbers.
         // If weights are e.g. 1, 1, direct multiplication is fine. If they are 1e18, divide by 1e18 after mul.
         // Let's assume weights are 1e18 for 1:1, so we need to divide by 1e18 afterwards.
         // Or assume weights are small integers (e.g., 1 to 100).
         // Let's assume weights are integers, 1 unit of weight = 1 unit of power multiplier.
         // This requires careful consideration of fixed-point arithmetic if weights aren't simple integers.
         // For this example, let's assume simple integer weights for power calculation.
         // E.g., 1 ST = stabilityWeight power, 1 QIP = influenceWeight power.

         uint256 totalPower = stakedBalance.mul(stabilityWeight) + influence.mul(influenceWeight);

         // If weights are intended as fractional multipliers (e.g. 0.5 -> 0.5e18)
         // totalPower = (stakedBalance.mul(stabilityWeight) + influence.mul(influenceWeight)) / 1e18;
         // Let's stick to integer weights for simplicity here.

         return totalPower;
    }


    /**
     * @dev Returns the current Quantum Influence Points for an address.
     * @param account The address to check.
     * @return The number of influence points.
     */
    function getInfluencePoints(address account) public view returns (uint256) {
        return quantumInfluencePoints[account];
    }

    /**
     * @dev Returns the value of a specific named flux parameter.
     * @param name The keccak256 hash of the parameter name.
     * @return The parameter's value. Returns 0 if not set.
     */
    function getFluxParameter(bytes32 name) public view returns (uint256) {
        return fluxParameters[name];
    }

    /**
     * @dev Calculates the minimum total voting power required for a proposal to reach quorum.
     * Based on the total supply of the staking token and the quorum denominator.
     * Note: This is a simplistic quorum based on total supply, not active voters or circulating supply.
     * A more robust system might use staked supply or a moving average.
     * @return The calculated quorum requirement.
     */
    function getQuorumVotes() public view returns (uint256) {
        // This calculation might need adjustment depending on how total supply and weights interact.
        // If total supply is in token units, and weight is 1e18, need to multiply then divide by 1e18.
        // Let's assume total supply is token units, and weights are integer multipliers.
        // The effective 'total possible power' would be (totalSupply * stabilityWeight) + (totalQIP * influenceWeight) - this is hard to track on-chain.
        // A more common approach is quorum as a percentage of *staked* tokens, or total votes cast.
        // Let's make quorum based on a percentage of the total voting power represented by token supply *at full weight*.
        // Total ST Power = totalSupply * stabilityWeight. Quorum = (Total ST Power / quorumDenominator).
        uint256 totalStakedTokenPower = STAKING_TOKEN.totalSupply().mul(stabilityWeight);
        // This ignores the influence part for quorum calculation, which is a simplification.
        // A true quorum for stake+influence would be complex to calculate based on total possible power.
        // Let's refine: Quorum is based on a percentage of the *total votes cast* + a minimum participation threshold.
        // Or Quorum is a fixed number / percentage of a baseline (e.g., total staked tokens).
        // Let's define quorum as a percentage of the *sum of all effective voting powers* at the end of voting.
        // This requires summing up all voters' powers, which is complex to calculate upfront.
        // A simpler quorum: based on the *total staked supply* * stabilityWeight, divided by denominator.
        // This means the influence part doesn't affect the *quorum* requirement, only the vote count.
        // Let's use this simpler approach for quorum.
        // For example, if staking token has 18 decimals, totalSupply is in wei. If stabilityWeight is 1e18,
        // then totalStakedTokenPower = totalSupply * 1e18. We need to divide by 1e18 AND quorumDenominator.
        // So, quorum = (totalSupply * stabilityWeight) / (1e18 * quorumDenominator).
        // Let's assume weights are 1:1 (stabilityWeight=1, influenceWeight=1) for calculation simplicity.
        // Then quorum = totalSupply / quorumDenominator.
        // If weights are large, we need to be careful. Let's use the large weights (e.g., 1e18).
        // Quorum votes needed = (total staked supply at snapshot * stabilityWeight / 1e18) / quorumDenominator.
        // Or, simpler: Quorum is a % of FOR + AGAINST votes. Let's use this.
        // Quorum = (total votes cast / quorumDenominator) for For+Against votes. This check happens *after* voting.
        // This function `getQuorumVotes` then represents the *minimum total votes cast* (For + Against) required.
        // Let's define quorumVotes as a simple percentage of a theoretical total.
        // Quorum = (STAKING_TOKEN.totalSupply() / quorumDenominator) * stabilityWeight? Still complex.

        // Let's make `quorumVotes` a govern-able parameter itself, removing this dynamic calculation complexity.
        // But the requirement is 20+ functions, so a view function is good.
        // Let's define quorum as: Total Supply of STAKING_TOKEN * stabilityWeight / 1e18 / quorumDenominator.
        // This requires `stabilityWeight` >= 1e18 or careful scaling. Let's assume `stabilityWeight` is >= 1e18.
         uint256 totalStabilitySupply = STAKING_TOKEN.totalSupply();
         if (stabilityWeight == 0) return 0; // Avoid division by zero if weight is 0

         // Calculate total potential stability power, then take a fraction
         uint256 totalPotentialStabilityPower = totalStabilitySupply.mul(stabilityWeight);
         // Now scale it back based on assumed 1e18 unit for weight
         // Example: 100 tokens (100e18 wei), stabilityWeight 1e18. Potential power = 100e36.
         // Scale back: 100e36 / 1e18 = 100e18.
         // Quorum: (100e18 / quorumDenominator).
         uint256 scaledPotentialStabilityPower;
         if (stabilityWeight >= 1e18) {
             scaledPotentialStabilityPower = totalPotentialStabilityPower / 1e18;
         } else {
              // Handle weights less than 1e18 - requires fixed point math or assumes weight is integer
              // Let's assume weights are integers 1-100 for simplicity of this calculation.
              // If weights are integers, totalPotentialStabilityPower = totalSupply * stabilityWeight
              // Quorum = totalPotentialStabilityPower / quorumDenominator
              // Need to pick one weight system. Let's stick to weights >= 1e18 and divide.
              // If stabilityWeight < 1e18, this division would lose precision if totalPotentialStabilityPower is small.
              // Let's revert to a simpler quorum calculation: percentage of the *total staked token supply*, ignoring influence for quorum baseline.
              // Quorum = (STAKING_TOKEN.totalSupply() / quorumDenominator) * stabilityWeight -- no, this overcounts.
              // Quorum = (STAKING_TOKEN.totalSupply() * (stabilityWeight / 1e18)) / quorumDenominator -- needs fixed point.
              // Easiest: Quorum is simply STAKING_TOKEN.totalSupply() / quorumDenominator. This means influence doesn't affect the *base* quorum number, only how easily someone reaches it. This seems like a reasonable simplification.
              scaledPotentialStabilityPower = totalPotentialStabilityPower / stabilityWeight; // Scale back to token units
              return scaledPotentialStabilityPower / quorumDenominator; // Quorum in token units
         }
         return scaledPotentialStabilityPower / quorumDenominator; // Quorum in token units
    }


    /**
     * @dev Returns the minimum voting power required to create a proposal.
     * @return The proposal threshold.
     */
    function getProposalThreshold() public view returns (uint256) {
        return proposalThreshold;
    }

    /**
     * @dev Returns the duration of the voting period in blocks.
     * @return The voting period.
     */
    function getVotingPeriod() public view returns (uint256) {
        return votingPeriod;
    }

     /**
     * @dev Returns the minimum time (in seconds) a proposal must spend in the queue.
     * @return The queue period.
     */
    function getQueuePeriod() public view returns (uint256) {
        return queuePeriod;
    }

     /**
     * @dev Returns the additional time delay (in seconds) after the queue period
     * before a proposal can be executed.
     * @return The execution delay.
     */
    function getExecutionDelay() public view returns (uint256) {
        return executionDelay;
    }

     /**
     * @dev Returns the current weight applied to staked tokens in voting power calculation.
     * @return The stability weight.
     */
    function getStabilityWeight() public view returns (uint256) {
        return stabilityWeight;
    }

     /**
     * @dev Returns the current weight applied to influence points in voting power calculation.
     * @return The influence weight.
     */
    function getInfluenceWeight() public view returns (uint256) {
        return influenceWeight;
    }

     /**
     * @dev Returns the address of the current guardian.
     * @return The guardian address.
     */
    function getGuardian() public view returns (address) {
        return guardian;
    }

    /**
     * @dev Returns the address of the staked token contract.
     * @return The staking token address.
     */
    function getStakingToken() public view returns (address) {
        return address(STAKING_TOKEN);
    }

    /**
     * @dev Returns the ID of the latest created proposal.
     * @return The latest proposal ID.
     */
    function getLatestProposalId() public view returns (uint256) {
        return proposalCount;
    }

     /**
     * @dev Returns the address that an account's voting power is currently delegated to.
     * @param account The account to check.
     * @return The delegatee address. Returns address(0) if not delegated.
     */
    function getDelegation(address account) public view returns (address) {
        address delegatee = delegates[account];
        if (delegatee == address(0)) {
            return account; // If not delegated, they vote for themselves
        }
        return delegatee;
    }

    /**
     * @dev Checks if an address has already voted on a specific proposal.
     * Note: This checks the original delegator's vote status, not the delegatee's.
     * @param proposalId The ID of the proposal.
     * @param account The address to check.
     * @return True if the account has voted, false otherwise.
     */
    function hasVoted(uint256 proposalId, address account) public view returns (bool) {
        return proposals[proposalId].hasVoted[account];
    }


    // --- Delegation Functions ---

    /**
     * @dev Delegates voting power (stake and influence) to another address.
     * @param delegatee The address to delegate to.
     * Requirements:
     * - Cannot delegate to self.
     */
    function delegate(address delegatee) external nonReentrant {
        if (delegatee == msg.sender) {
            revert QuantumFluxGovernor__CannotDelegateToSelf();
        }
        address currentDelegate = delegates[msg.sender];
        delegates[msg.sender] = delegatee;
        emit DelegateChanged(msg.sender, currentDelegate, delegatee);

        // Note: DelegateVotesChanged event is typically emitted when the *balance* changes for a delegatee
        // due to someone delegating *to* them or *from* them.
        // Tracking this requires accumulating delegated power, which adds complexity (like OpenZeppelin's checkpointing).
        // For this example, we simplify and just update the mapping, and voting power calculation is dynamic.
        // A full implementation would track historical votes/delegations for vote power snapshots.
        // We emit it conceptually here, but the `previousBalance` and `newBalance` would require
        // state tracking or recalculation, which is omitted for brevity.
        // Let's omit this event emission for this simplified delegation model.
        // emit DelegateVotesChanged(delegatee, ?, ?);
    }

    /**
     * @dev Delegates voting power using an EIP-712 signature.
     * @param delegator The address delegating.
     * @param delegatee The address to delegate to.
     * @param nonce The EIP-712 nonce.
     * @param expiry The signature expiry timestamp.
     * @param v, r, s The signature components.
     * Note: Signature verification logic needs to be implemented or integrated.
     * This function signature is included for conceptual completeness for the 20+ function count.
     */
    function delegateBySig(address delegator, address delegatee, uint256 nonce, uint256 expiry, uint8 v, bytes32 r, bytes32 s) external {
         // @TODO: Implement EIP-712 signature verification for delegation
         // Requires domain separator, message hash calculation, recovering address.
         // Check nonce to prevent replay attacks.
         // Check expiry timestamp.
         // If valid, call delegate(delegatee) as if delegator called it.
         revert("delegateBySig not fully implemented"); // Placeholder
         // Example call if signature were valid: delegate(delegatee); // Called *as* delegator
    }

    // --- Influence Point Management (Guardian/Governance Only) ---

    /**
     * @dev Awards Quantum Influence Points to an address.
     * Callable only by the guardian or via a successful governance proposal execution.
     * @param recipient The address to award points to.
     * @param amount The number of points to award.
     */
    function awardInfluencePoints(address recipient, uint256 amount) external nonReentrant {
        // Check if called by guardian OR by this contract itself during proposal execution
        if (msg.sender != guardian && msg.sender != address(this)) {
            revert QuantumFluxGovernor__Unauthorized();
        }
        if (amount == 0) {
             revert QuantumFluxGovernor__InvalidInfluenceAmount();
        }
        quantumInfluencePoints[recipient] = quantumInfluencePoints[recipient].add(amount);
        emit InfluencePointsAwarded(recipient, amount, msg.sender);
    }

    /**
     * @dev Slashes (reduces) Quantum Influence Points for an address.
     * Callable only by the guardian or via a successful governance proposal execution.
     * @param recipient The address to slash points from.
     * @param amount The number of points to slash.
     * Requirements:
     * - Recipient must have sufficient points.
     */
    function slashInfluencePoints(address recipient, uint256 amount) external nonReentrant {
         // Check if called by guardian OR by this contract itself during proposal execution
        if (msg.sender != guardian && msg.sender != address(this)) {
            revert QuantumFluxGovernor__Unauthorized();
        }
         if (amount == 0) {
             revert QuantumFluxGovernor__InvalidInfluenceAmount();
         }
         if (quantumInfluencePoints[recipient] < amount) {
             revert QuantumFluxGovernor__SlashedInfluenceExceedsBalance();
         }
        quantumInfluencePoints[recipient] = quantumInfluencePoints[recipient].sub(amount);
        emit InfluencePointsSlashed(recipient, amount, msg.sender);
    }


    // --- Internal/Helper Functions ---

     /**
      * @dev Internal function to set a flux parameter. Callable only by execute().
      * @param name The keccak256 hash of the parameter name.
      * @param value The new value for the parameter.
      */
    function _setFluxParameter(bytes32 name, uint256 value) internal onlySelf {
        uint256 oldValue = fluxParameters[name];
        fluxParameters[name] = value;
        emit FluxParameterChanged(name, oldValue, value, msg.sender);
    }

     /**
      * @dev Internal function to set the voting power weights. Callable only by execute().
      * @param _stabilityWeight The new weight for staked tokens.
      * @param _influenceWeight The new weight for influence points.
      */
    function _setWeights(uint256 _stabilityWeight, uint256 _influenceWeight) internal onlySelf {
        uint256 oldStabilityWeight = stabilityWeight;
        uint256 oldInfluenceWeight = influenceWeight;
        stabilityWeight = _stabilityWeight;
        influenceWeight = _influenceWeight;
        emit VotingWeightsChanged(oldStabilityWeight, stabilityWeight, oldInfluenceWeight, influenceWeight, msg.sender);
    }

     /**
      * @dev Internal helper function to update various governance parameters. Callable only by execute().
      * Uses bytes32 to identify the parameter name and uint256 for the new value.
      * This is a pattern to allow governance to update its own settings dynamically.
      * @param paramName The keccak256 hash of the parameter name (e.g., keccak256("votingPeriod")).
      * @param newValue The new value for the parameter.
      */
     function _updateGovernanceParameter(bytes32 paramName, uint256 newValue) internal onlySelf {
         uint256 oldValue;
         if (paramName == keccak256("votingPeriod")) {
             oldValue = votingPeriod; votingPeriod = newValue;
         } else if (paramName == keccak256("queuePeriod")) {
             oldValue = queuePeriod; queuePeriod = newValue;
         } else if (paramName == keccak256("executionDelay")) {
             oldValue = executionDelay; executionDelay = newValue;
         } else if (paramName == keccak256("proposalThreshold")) {
             oldValue = proposalThreshold; proposalThreshold = newValue;
         } else if (paramName == keccak256("quorumDenominator")) {
              // quorumDenominator affects getQuorumVotes(), handle carefully
              // Avoid division by zero if newValue is 0
             if (newValue == 0) revert QuantumFluxGovernor__InvalidState(); // Or specific error
             oldValue = quorumDenominator; quorumDenominator = newValue;
         }
         // Add more parameters here as needed
         else {
             revert QuantumFluxGovernor__InvalidState(); // Or specific error for unknown param
         }
         emit GovernanceParameterChanged(paramName, oldValue, newValue, msg.sender);
     }


     /**
      * @dev Evaluates an optional on-chain condition included in a proposal.
      * The condition bytes are expected to encode a call to a specific contract/function
      * within the protocol that returns a boolean.
      * This is a simplified example. Real-world conditions might involve complex checks
      * or interaction with oracle data verified via ZK proofs etc.
      * Format: `bytes condition = abi.encodePacked(target_address, bytes4_function_selector, encoded_args);`
      * @param conditionBytes The bytes representing the condition call.
      * @return True if the condition evaluates to true, false otherwise. Reverts on invalid format/call.
      */
     function _checkCondition(bytes memory conditionBytes) internal view returns (bool) {
         if (conditionBytes.length < 24) { // Needs at least address (20) + selector (4)
             revert QuantumFluxGovernor__InvalidConditionFormat();
         }

         address target = address(bytes20(conditionBytes[0:20]));
         bytes4 selector = bytes4(conditionBytes[20:24]);
         bytes memory callData = conditionBytes[24:]; // Remaining bytes are args

         bytes memory encodedCall = abi.encodePacked(selector, callData);

         // Perform the staticcall to the target contract
         (bool success, bytes memory returnData) = target.staticcall(encodedCall);

         // The called function is expected to return a boolean
         if (!success) {
             // Condition check failed (e.g., target reverted). Interpret as condition not met.
             // Or potentially revert with more info: `assembly { revert(add(0x20, returnData), mload(returnData)) }`
             return false; // Or revert if call must succeed
         }

         // Decode the boolean result from the return data
         if (returnData.length != 32) { // Boolean returns as a padded uint256 (32 bytes)
             revert QuantumFluxGovernor__InvalidConditionFormat();
         }
         bool conditionResult = abi.decode(returnData, (bool));

         return conditionResult;
     }


    /**
     * @dev Computes the hash of a proposal. Used for signature validation (e.g., castVoteBySig).
     * @param targets The addresses of the contracts to call.
     * @param values The ether values to send with each call.
     * @param calldatas The calldata for each call.
     * @param condition An optional bytes payload representing an on-chain condition check.
     * @param description The description of the proposal.
     * @return The keccak256 hash of the proposal details.
     */
    function hashProposal(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata calldatas,
        bytes calldata condition,
        string calldata description
    ) public pure returns (bytes32) {
         // Hashing logic needs to be robust and match the signing payload if using EIP-712
         // For simplicity here, a basic hash of combined inputs:
         // A more standard approach might use a struct hash as per EIP-712.
         // Example basic hash:
        return keccak256(
            abi.encode(
                targets,
                values,
                calldatas,
                condition,
                keccak256(bytes(description)) // Hash description separately if long
            )
        );
    }

    /**
     * @dev Internal hook executed before proposal actions are called during execution.
     * Can be used for pre-execution checks or state changes.
     * @param proposalId The ID of the proposal being executed.
     */
    function _beforeExecute(uint256 proposalId) internal {
        // Placeholder for potential custom logic
        // Example: Log specific data, pause parts of the protocol, etc.
    }

    /**
     * @dev Internal hook executed after proposal actions are called during execution.
     * Can be used for post-execution cleanup or state changes.
     * @param proposalId The ID of the proposal that was executed.
     */
    function _afterExecute(uint256 proposalId) internal {
        // Placeholder for potential custom logic
        // Example: Resume paused protocol parts, trigger dependent actions, etc.
    }


    // --- Governance Parameter Update Functions (Callable only by execute) ---

    // These functions are intended to be called ONLY by the `execute` function
    // of THIS contract, as part of a successful governance proposal.
    // This is enforced by the `onlySelf` modifier.

    /**
     * @dev Sets the duration of the voting period in blocks.
     * Callable only by a successful governance proposal executing.
     * @param _votingPeriod The new voting period.
     */
    function setVotingPeriod(uint256 _votingPeriod) external onlySelf {
        _updateGovernanceParameter(keccak256("votingPeriod"), _votingPeriod);
    }

    /**
     * @dev Sets the minimum time (in seconds) a proposal must spend in the queue.
     * Callable only by a successful governance proposal executing.
     * @param _queuePeriod The new queue period.
     */
    function setQueuePeriod(uint256 _queuePeriod) external onlySelf {
        _updateGovernanceParameter(keccak256("queuePeriod"), _queuePeriod);
    }

    /**
     * @dev Sets the additional time delay (in seconds) after the queue period
     * before a proposal can be executed.
     * Callable only by a successful governance proposal executing.
     * @param _executionDelay The new execution delay.
     */
    function setExecutionDelay(uint256 _executionDelay) external onlySelf {
        _updateGovernanceParameter(keccak256("executionDelay"), _executionDelay);
    }

    /**
     * @dev Sets the minimum voting power required to create a proposal.
     * Callable only by a successful governance proposal executing.
     * @param _proposalThreshold The new proposal threshold.
     */
    function setProposalThreshold(uint256 _proposalThreshold) external onlySelf {
        _updateGovernanceParameter(keccak256("proposalThreshold"), _proposalThreshold);
    }

    /**
     * @dev Sets the quorum denominator. Quorum is calculated based on this.
     * Callable only by a successful governance proposal executing.
     * @param _quorumDenominator The new quorum denominator.
     */
    function setQuorumDenominator(uint256 _quorumDenominator) external onlySelf {
        _updateGovernanceParameter(keccak256("quorumDenominator"), _quorumDenominator);
    }

    /**
     * @dev Sets the weight applied to staked tokens in voting power calculation.
     * Callable only by a successful governance proposal executing.
     * @param _stabilityWeight The new stability weight.
     */
    function setStabilityWeight(uint256 _stabilityWeight) external onlySelf {
        _setWeights(_stabilityWeight, influenceWeight);
    }

    /**
     * @dev Sets the weight applied to influence points in voting power calculation.
     * Callable only by a successful governance proposal executing.
     * @param _influenceWeight The new influence weight.
     */
    function setInfluenceWeight(uint256 _influenceWeight) external onlySelf {
        _setWeights(stabilityWeight, _influenceWeight);
    }

    /**
     * @dev Sets the address of the guardian.
     * Callable only by a successful governance proposal executing.
     * @param _guardian The new guardian address.
     */
    function setGuardian(address _guardian) external onlySelf {
        address oldGuardian = guardian;
        guardian = _guardian;
         // No specific event for just guardian change via this helper, uses GovernanceParameterChanged if needed.
         // Or emit custom event? Let's just use GovernanceParameterChanged.
         // emit GovernanceParameterChanged(keccak256("guardian"), uint256(uint160(oldGuardian)), uint256(uint160(_guardian)), msg.sender); // Casting address to uint256 for event
    }

     /**
     * @dev Sets the address of the staking token. Use with extreme caution.
     * Callable only by a successful governance proposal executing.
     * @param _stakingToken The new staking token address.
     */
    function setStakingToken(address _stakingToken) external onlySelf {
         // This is very dangerous and should be handled carefully in a real system.
         // Maybe only callable once, or via a very high threshold/delay.
         // STAKING_TOKEN is immutable, so this function is actually impossible to call.
         // If it were mutable, the code would look like:
         // address oldToken = address(STAKING_TOKEN);
         // STAKING_TOKEN = IERC20(_stakingToken);
         // emit GovernanceParameterChanged(keccak256("stakingToken"), uint256(uint160(oldToken)), uint256(uint160(_stakingToken)), msg.sender);
         revert("STAKING_TOKEN is immutable"); // Cannot change immutable state variable
    }


    // --- Placeholder/Advanced Functions (Examples/Helpers) ---

    /**
     * @dev Helper function to generate calldata for proposing a change to a flux parameter.
     * Can be used off-chain or within a contract proposing actions.
     * @param name The keccak256 hash of the parameter name.
     * @param value The new value for the parameter.
     * @return The target address and calldata required for the proposal.
     */
    function proposeSetFluxParameter(bytes32 name, uint256 value) external pure returns (address target, bytes memory calldata_) {
        return (address(this), abi.encodeWithSelector(this._setFluxParameter.selector, name, value));
    }

    /**
     * @dev Helper function to generate calldata for proposing a change to voting power weights.
     * @param _stabilityWeight The new stability weight.
     * @param _influenceWeight The new influence weight.
     * @return The target address and calldata required for the proposal.
     */
     function proposeSetWeights(uint256 _stabilityWeight, uint256 _influenceWeight) external pure returns (address target, bytes memory calldata_) {
         return (address(this), abi.encodeWithSelector(this._setWeights.selector, _stabilityWeight, _influenceWeight));
     }

    /**
     * @dev Helper function to generate calldata for proposing a change to various governance parameters.
     * @param paramName The keccak256 hash of the parameter name.
     * @param newValue The new value.
     * @return The target address and calldata required for the proposal.
     */
     function proposeUpdateGovernanceParameter(bytes32 paramName, uint256 newValue) external pure returns (address target, bytes memory calldata_) {
         return (address(this), abi.encodeWithSelector(this._updateGovernanceParameter.selector, paramName, newValue));
     }


     /**
      * @dev Alias for the execute function, highlighting its use for conditional proposals.
      * @param proposalId The ID of the proposal to execute.
      */
     function executeConditionalProposal(uint256 proposalId) external payable {
         execute(proposalId);
     }

     /**
      * @dev Public function to check the current status of a proposal's optional condition.
      * Useful for understanding if a 'Queued' proposal is currently executable regarding its condition.
      * @param proposalId The ID of the proposal.
      * @return True if the condition is met, false otherwise.
      * Reverts if the proposal has no condition or is not found.
      */
     function checkProposalCondition(uint256 proposalId) public view returns (bool) {
         Proposal storage proposal = proposals[proposalId];
         if (proposal.id == 0 || proposalId > proposalCount) {
             revert("Invalid proposal ID"); // Or specific error
         }
         if (proposal.condition.length == 0) {
             revert("Proposal has no condition");
         }
         return _checkCondition(proposal.condition);
     }

     // --- Batch Functions (Concepts - Implementation Omitted for brevity) ---

     /**
      * @dev Concept: Allows proposing multiple independent sets of actions in a single transaction.
      * Requires careful handling of proposal IDs and atomicity.
      * function batchPropose(...) external returns (uint256[] memory proposalIds) { ... }
      */

     /**
      * @dev Concept: Allows delegating to multiple addresses in a single transaction.
      * Could be useful for managing complex delegation strategies.
      * function batchDelegate(address[] calldata delegators, address[] calldata delegatees) external { ... }
      */
}
```