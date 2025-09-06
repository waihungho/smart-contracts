This smart contract, **AegisProtocol**, is designed as a Decentralized Autonomous Investment Protocol. Its core innovation lies in a dynamic, reputation-weighted governance model combined with community oversight of AI-assisted portfolio rebalancing, and a novel approach to mitigating flash loan governance attacks. It focuses on strategic asset management, allowing users to propose and vote on investment strategies that interact with external DeFi protocols, all while building an on-chain reputation based on their historical performance and contributions.

---

## AegisProtocol: Outline and Function Summary

**Contract Name:** `AegisProtocol`

**Core Concepts:**
*   **Dynamic Reputation System:** Users' voting power and influence are directly tied to their historical success in proposing or supporting profitable investment strategies.
*   **AI-Assisted Strategic Governance:** External AI (simulated via oracle input) suggests optimal portfolio rebalances, which are then subjected to a decentralized vote by the community.
*   **Proof-of-Contribution Badges (SBTs):** Non-transferable NFTs reward significant contributions (successful strategies, active participation), enhancing reputation and potential access tiers.
*   **Modular DeFi Integration:** The protocol can be extended to interact with various external DeFi platforms (e.g., lending protocols, AMMs) through a system of approved adapters.
*   **Flash Loan Resilience Scoring:** A dynamic, on-chain mechanism to assess the "trustworthiness" of voting power based on recent activity, aiming to mitigate flash loan governance attacks by adjusting voting thresholds.
*   **Timelocked Execution:** Critical operations (strategy execution, DAO parameter changes) are subject to timelocks for enhanced security and community oversight.

---

### Function Summary:

**I. Core Strategy Management & Execution**
1.  **`proposeInvestmentStrategy(string calldata _description, address[] calldata _targetAssets, uint256[] calldata _targetAllocationsBps)`**: Allows any user to propose a new investment strategy, defining target assets and their percentage allocations (in Basis Points).
2.  **`voteOnStrategyProposal(uint256 _strategyId, bool _support)`**: Enables users to vote for or against a proposed strategy. Voting power is dynamically weighted by their current `reputationScore`.
3.  **`evaluateStrategyPerformance(uint256 _strategyId, int256 _netProfitPercentage)`**: A designated oracle or multi-sig reports the actual performance (profit/loss percentage) of a completed strategy. This triggers `updateUserReputation` for participants.
4.  **`queueStrategyExecution(uint256 _strategyId)`**: Moves an approved strategy into a timelock queue, making it ready for execution after a waiting period.
5.  **`executeQueuedStrategy(uint256 _strategyId)`**: Executes a strategy from the timelock queue, deploying funds to external DeFi protocols via pre-approved adapters.

**II. AI-Assisted Rebalancing & Simulation**
6.  **`triggerAIRebalanceProposal(address[] calldata _newTargetAssets, uint256[] calldata _newTargetAllocationsBps)`**: A trusted oracle (simulating an AI's output) proposes a new optimal portfolio allocation based on market conditions.
7.  **`voteOnAIRebalanceProposal(uint256 _rebalanceProposalId, bool _support)`**: Users vote to approve or reject the AI-suggested rebalance. Reputation-weighted.
8.  **`executeApprovedAIRebalance(uint256 _rebalanceProposalId)`**: Executes an approved AI rebalance, adjusting the protocol's portfolio via adapters.
9.  **`simulateStrategyExecution(uint256 _strategyId)`**: Allows anyone to run a "dry-run" simulation of an existing strategy's execution using current market data (via price oracles), providing transparency on potential outcomes without moving funds.

**III. Reputation & Contribution Management**
10. **`getReputationScore(address _user)`**: Returns the current dynamic reputation score of a specified user, reflecting their historical success and contributions.
11. **`mintContributionBadge(address _recipient, string calldata _badgeURI, uint256 _badgeLevel)`**: Mints a non-transferable ERC721 token (SBT) as a "Proof-of-Contribution" badge for significant actions (e.g., proposing a highly profitable strategy, consistent positive voting).
12. **`getContributionBadges(address _user)`**: Retrieves a list of Contribution Badge NFTs owned by a specific user.

**IV. Funds Management**
13. **`depositFunds(address _asset, uint256 _amount)`**: Users deposit specific ERC20 assets into the protocol's main vault to participate in strategies.
14. **`withdrawFunds(address _asset, uint256 _amount)`**: Users withdraw their available share of deposited funds, ensuring funds allocated to active strategies remain locked.
15. **`redeemStrategyProfits(uint256 _strategyId)`**: Allows participants in a completed, profitable strategy to claim their pro-rata share of the profits.
16. **`getProtocolPortfolioAllocation()`**: Provides a real-time overview of the current asset distribution and total value locked across the entire protocol's portfolio.

**V. Governance, Extensibility & Security**
17. **`proposeDAOParameterChange(bytes32 _parameterName, uint256 _newValue)`**: Allows DAO members to propose changes to core protocol parameters (e.g., voting periods, fees).
18. **`voteOnDAOProposal(uint256 _proposalId, bool _support)`**: Users vote on DAO parameter change proposals, reputation-weighted.
19. **`executeDAOProposal(uint256 _proposalId)`**: Executes an approved DAO proposal after its timelock period.
20. **`setExternalProtocolAdapter(address _asset, address _adapterContract)`**: Enables the DAO to approve and register new external DeFi protocol adapters, allowing the AegisProtocol to interact with new yield sources.
21. **`getFlashLoanResilienceScore(address _account)`**: Calculates a dynamic score for an account based on its recent on-chain activity and history (e.g., age of tokens, transaction frequency). This score can be used to dynamically adjust minimum voting thresholds for critical governance actions, making flash-loan-based governance attacks more difficult.
22. **`emergencyPauseFunds(bool _pause)`**: A multi-sig or DAO-controlled function to emergency pause all fund deposits, withdrawals, and strategy executions in case of critical vulnerabilities. (Added for comprehensive security)

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol"; // For efficient tracking of sets

/**
 * @title AegisProtocol
 * @dev Decentralized Autonomous Investment Protocol with Dynamic Reputation, AI-Assisted Governance,
 *      and Flash Loan Resilience.
 *
 * This contract enables community-driven investment strategies, where users propose and vote on
 * strategies. Voting power is determined by a dynamic reputation score, which is updated based on
 * the historical performance of strategies they supported. It also integrates a simulated AI for
 * rebalancing proposals, subject to community approval. Novel features include Proof-of-Contribution
 * Badges (SBTs) and a dynamic Flash Loan Resilience Score to enhance governance security.
 *
 * Outline and Function Summary:
 *
 * I. Core Strategy Management & Execution
 * 1. proposeInvestmentStrategy(string calldata _description, address[] calldata _targetAssets, uint256[] calldata _targetAllocationsBps)
 * 2. voteOnStrategyProposal(uint256 _strategyId, bool _support)
 * 3. evaluateStrategyPerformance(uint256 _strategyId, int256 _netProfitPercentage)
 * 4. queueStrategyExecution(uint256 _strategyId)
 * 5. executeQueuedStrategy(uint256 _strategyId)
 *
 * II. AI-Assisted Rebalancing & Simulation
 * 6. triggerAIRebalanceProposal(address[] calldata _newTargetAssets, uint256[] calldata _newTargetAllocationsBps)
 * 7. voteOnAIRebalanceProposal(uint256 _rebalanceProposalId, bool _support)
 * 8. executeApprovedAIRebalance(uint256 _rebalanceProposalId)
 * 9. simulateStrategyExecution(uint256 _strategyId)
 *
 * III. Reputation & Contribution Management
 * 10. getReputationScore(address _user)
 * 11. mintContributionBadge(address _recipient, string calldata _badgeURI, uint256 _badgeLevel)
 * 12. getContributionBadges(address _user)
 *
 * IV. Funds Management
 * 13. depositFunds(address _asset, uint256 _amount)
 * 14. withdrawFunds(address _asset, uint256 _amount)
 * 15. redeemStrategyProfits(uint256 _strategyId)
 * 16. getProtocolPortfolioAllocation()
 *
 * V. Governance, Extensibility & Security
 * 17. proposeDAOParameterChange(bytes32 _parameterName, uint256 _newValue)
 * 18. voteOnDAOProposal(uint256 _proposalId, bool _support)
 * 19. executeDAOProposal(uint256 _proposalId)
 * 20. setExternalProtocolAdapter(address _asset, address _adapterContract)
 * 21. getFlashLoanResilienceScore(address _account)
 * 22. emergencyPauseFunds(bool _pause)
 */
contract AegisProtocol is Ownable, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    // --- Custom Errors ---
    error InvalidAllocation();
    error StrategyNotFound();
    error StrategyNotProposable();
    error StrategyNotVotable();
    error StrategyAlreadyEvaluated();
    error StrategyNotExecutable();
    error StrategyAlreadyExecuted();
    error StrategyNotQueued();
    error StrategyExecutionTimeNotReached();
    error InsufficientFundsForStrategy();
    error InsufficientFundsToWithdraw();
    error WithdrawAmountExceedsAvailable();
    error ZeroAmount();
    error Unauthorized();
    error OracleNotSet();
    error AdapterNotSet();
    error InvalidAdapter();
    error RebalanceNotFound();
    error RebalanceNotVotable();
    error RebalanceNotExecutable();
    error RebalanceExecutionTimeNotReached();
    error RebalanceAlreadyExecuted();
    error DAOProposalNotFound();
    error DAOProposalNotVotable();
    error DAOProposalNotExecutable();
    error DAOExecutionTimeNotReached();
    error InvalidBadgeLevel();
    error FlashLoanResilienceTooLow();
    error Paused();
    error NotPaused();

    // --- State Variables ---

    // Governance Parameters
    struct GovernanceParams {
        uint256 minVotePeriod; // Minimum time for voting on proposals
        uint256 executionTimelock; // Time delay before an approved action can be executed
        uint256 minStrategyDeposit; // Minimum value (in USD, or a base asset equivalent) to propose a strategy
        uint256 minReputationForProposing; // Minimum reputation score to propose a strategy
        uint256 quorumPercentage; // Percentage of total reputation needed for a proposal to pass (e.g., 40%)
        uint256 positiveVoteThresholdPercentage; // Percentage of positive votes needed to pass (e.g., 51%)
        uint256 aiProposalTimelock; // Timelock for AI rebalance proposals
        uint256 daoProposalTimelock; // Timelock for DAO parameter changes
    }
    GovernanceParams public governanceParams;

    // External Protocol Adapters (for interacting with Aave, Compound, Uniswap etc.)
    // assetAddress -> AdapterContract
    mapping(address => address) public externalProtocolAdapters;

    // Oracles (e.g., price feeds, AI recommendation provider)
    address public priceOracle;
    address public aiOracle; // Address that can trigger AI rebalance proposals
    address public strategyPerformanceOracle; // Address that can evaluate strategy performance

    // User Reputation
    mapping(address => int256) public reputationScores;
    uint256 public constant REPUTATION_MULTIPLIER = 1e18; // To handle fractional reputation as int256

    // Contribution Badges (ERC721 Non-Transferable Tokens / SBTs)
    ContributionBadges public contributionBadges;
    uint256 private _badgeTokenIdCounter;

    // Funds Management
    mapping(address => mapping(address => uint256)) public userBalances; // asset => user => amount
    mapping(address => uint256) public protocolTotalBalances; // asset => total amount held by protocol

    // Strategy Management
    enum StrategyStatus { Proposed, Voting, Approved, Rejected, QueuedForExecution, Executed, Evaluated }
    struct Strategy {
        address proposer;
        string description;
        address[] targetAssets;
        uint256[] targetAllocationsBps; // In basis points (e.g., 5000 for 50%)
        uint256 proposalTime;
        uint256 votingEndTime;
        uint256 totalReputationFor;
        uint256 totalReputationAgainst;
        uint256 totalParticipatingReputation; // Sum of reputation scores of all voters
        StrategyStatus status;
        uint256 executionTime; // Timestamp when it can be executed
        int256 netProfitPercentage; // Stored after evaluation (e.g., 500 for +5%, -200 for -2%)
        EnumerableSet.AddressSet voters;
    }
    mapping(uint256 => Strategy) public strategies;
    uint256 private _strategyIdCounter;

    // AI Rebalance Proposals
    enum RebalanceStatus { Proposed, Voting, Approved, Rejected, QueuedForExecution, Executed }
    struct AIRebalanceProposal {
        address proposer; // The AI Oracle
        address[] newTargetAssets;
        uint256[] newTargetAllocationsBps;
        uint256 proposalTime;
        uint256 votingEndTime;
        uint256 totalReputationFor;
        uint256 totalReputationAgainst;
        uint256 totalParticipatingReputation;
        RebalanceStatus status;
        uint256 executionTime; // Timestamp when it can be executed
        EnumerableSet.AddressSet voters;
    }
    mapping(uint256 => AIRebalanceProposal) public aiRebalanceProposals;
    uint256 private _aiRebalanceIdCounter;

    // DAO Parameter Changes
    enum DAOProposalStatus { Proposed, Voting, Approved, Rejected, QueuedForExecution, Executed }
    struct DAOProposal {
        address proposer; // initiator of the proposal (can be any user meeting criteria)
        bytes32 parameterName;
        uint256 newValue;
        uint256 proposalTime;
        uint256 votingEndTime;
        uint256 totalReputationFor;
        uint256 totalReputationAgainst;
        uint256 totalParticipatingReputation;
        DAOProposalStatus status;
        uint256 executionTime; // Timestamp when it can be executed
        EnumerableSet.AddressSet voters;
    }
    mapping(uint256 => DAOProposal) public daoProposals;
    uint256 private _daoProposalIdCounter;

    // Paused State
    bool public paused;

    // --- Events ---
    event StrategyProposed(uint256 indexed strategyId, address indexed proposer, string description);
    event StrategyVoted(uint256 indexed strategyId, address indexed voter, bool support, int256 reputationScore);
    event StrategyApproved(uint256 indexed strategyId);
    event StrategyRejected(uint256 indexed strategyId);
    event StrategyQueuedForExecution(uint256 indexed strategyId, uint256 executionTime);
    event StrategyExecuted(uint256 indexed strategyId);
    event StrategyEvaluated(uint256 indexed strategyId, int256 netProfitPercentage);
    event FundsDeposited(address indexed user, address indexed asset, uint256 amount);
    event FundsWithdrawn(address indexed user, address indexed asset, uint256 amount);
    event ProfitsRedeemed(uint256 indexed strategyId, address indexed user, address indexed asset, uint256 amount);
    event ReputationUpdated(address indexed user, int256 newReputation);
    event ContributionBadgeMinted(address indexed recipient, uint256 indexed tokenId, string badgeURI, uint256 badgeLevel);
    event AIRebalanceProposed(uint256 indexed proposalId, address indexed proposer);
    event AIRebalanceVoted(uint256 indexed proposalId, address indexed voter, bool support, int256 reputationScore);
    event AIRebalanceApproved(uint256 indexed proposalId);
    event AIRebalanceRejected(uint256 indexed proposalId);
    event AIRebalanceQueuedForExecution(uint256 indexed proposalId, uint256 executionTime);
    event AIRebalanceExecuted(uint256 indexed proposalId);
    event DAOProposalProposed(uint256 indexed proposalId, address indexed proposer, bytes32 parameterName, uint256 newValue);
    event DAOProposalVoted(uint256 indexed proposalId, address indexed voter, bool support, int256 reputationScore);
    event DAOProposalApproved(uint256 indexed proposalId);
    event DAOProposalRejected(uint256 indexed proposalId);
    event DAOProposalQueuedForExecution(uint256 indexed proposalId, uint256 executionTime);
    event DAOProposalExecuted(uint256 indexed proposalId);
    event ExternalProtocolAdapterSet(address indexed asset, address indexed adapterContract);
    event ProtocolPaused(address indexed by);
    event ProtocolUnpaused(address indexed by);


    // --- Constructor ---
    constructor(address _priceOracle, address _aiOracle, address _strategyPerformanceOracle) Ownable(msg.sender) {
        if (_priceOracle == address(0) || _aiOracle == address(0) || _strategyPerformanceOracle == address(0)) {
            revert OracleNotSet();
        }
        priceOracle = _priceOracle;
        aiOracle = _aiOracle;
        strategyPerformanceOracle = _strategyPerformanceOracle;

        // Initialize reputation for the deployer as a starting point
        reputationScores[msg.sender] = 100 * int256(REPUTATION_MULTIPLIER);

        // Initialize default governance parameters
        governanceParams = GovernanceParams({
            minVotePeriod: 3 days,
            executionTimelock: 1 days,
            minStrategyDeposit: 100 ether, // e.g., 100 USDC equivalent
            minReputationForProposing: 10 * int256(REPUTATION_MULTIPLIER), // e.g., 10 reputation points
            quorumPercentage: 4000, // 40%
            positiveVoteThresholdPercentage: 5100, // 51%
            aiProposalTimelock: 12 hours,
            daoProposalTimelock: 3 days
        });

        contributionBadges = new ContributionBadges();
        _badgeTokenIdCounter = 0;
        paused = false;
    }

    // --- Modifiers ---
    modifier onlyPriceOracle() {
        if (msg.sender != priceOracle) revert Unauthorized();
        _;
    }

    modifier onlyAIOracle() {
        if (msg.sender != aiOracle) revert Unauthorized();
        _;
    }

    modifier onlyStrategyPerformanceOracle() {
        if (msg.sender != strategyPerformanceOracle) revert Unauthorized();
        _;
    }

    modifier whenNotPaused() {
        if (paused) revert Paused();
        _;
    }

    modifier whenPaused() {
        if (!paused) revert NotPaused();
        _;
    }

    // --- Helper Functions ---
    function _validateAllocations(address[] calldata _assets, uint256[] calldata _allocations) internal pure {
        if (_assets.length == 0 || _assets.length != _allocations.length) revert InvalidAllocation();
        uint256 totalAllocation = 0;
        for (uint256 i = 0; i < _allocations.length; i++) {
            totalAllocation += _allocations[i];
        }
        if (totalAllocation != 10000) revert InvalidAllocation(); // Total must be 10000 bps (100%)
    }

    function _getFlashLoanAdjustedReputation(address _user, int256 _baseReputation) internal view returns (int256) {
        uint256 resilienceScore = getFlashLoanResilienceScore(_user);
        // Example: If resilienceScore is 0, voting power is halved. If 100, no change.
        // This is a simplified example; a real implementation might use more complex curves or external data.
        if (resilienceScore < 50) { // If score is below a certain threshold
            return (_baseReputation * int256(resilienceScore)) / 100; // Reduce voting power proportionally
        }
        return _baseReputation;
    }

    function _isProposalApproved(uint256 _totalReputationFor, uint256 _totalReputationAgainst, uint256 _totalParticipatingReputation) internal view returns (bool) {
        if (_totalParticipatingReputation == 0) return false;
        uint256 votesForPercentage = (_totalReputationFor * 10000) / _totalParticipatingReputation;
        uint256 quorumReached = (_totalParticipatingReputation * 10000) / _getTotalProtocolReputation(); // Assuming a way to get total reputation
        return quorumReached >= governanceParams.quorumPercentage && votesForPercentage >= governanceParams.positiveVoteThresholdPercentage;
    }

    function _getTotalProtocolReputation() internal view returns (uint256) {
        // This is a placeholder. In a real system, you'd iterate through all users
        // or maintain a cached sum to get the total circulating reputation.
        // For demonstration, we'll assume a fixed or approximated value.
        // A more robust implementation might use a snapshot of reputation or a token supply if reputation was tokenized.
        return 10000 * int256(REPUTATION_MULTIPLIER); // Example: 10,000 total reputation points
    }

    // --- I. Core Strategy Management & Execution ---

    /**
     * @dev Proposes a new investment strategy.
     * @param _description A brief description of the strategy.
     * @param _targetAssets The array of ERC20 token addresses to invest in.
     * @param _targetAllocationsBps The target allocation for each asset in basis points (e.g., 5000 for 50%).
     */
    function proposeInvestmentStrategy(
        string calldata _description,
        address[] calldata _targetAssets,
        uint256[] calldata _targetAllocationsBps
    ) external whenNotPaused nonReentrant {
        if (reputationScores[msg.sender] < governanceParams.minReputationForProposing) {
            revert Unauthorized();
        }
        _validateAllocations(_targetAssets, _targetAllocationsBps);

        uint256 strategyId = _strategyIdCounter++;
        strategies[strategyId] = Strategy({
            proposer: msg.sender,
            description: _description,
            targetAssets: _targetAssets,
            targetAllocationsBps: _targetAllocationsBps,
            proposalTime: block.timestamp,
            votingEndTime: block.timestamp + governanceParams.minVotePeriod,
            totalReputationFor: 0,
            totalReputationAgainst: 0,
            totalParticipatingReputation: 0,
            status: StrategyStatus.Voting,
            executionTime: 0,
            netProfitPercentage: 0,
            voters: EnumerableSet.AddressSet(0)
        });

        emit StrategyProposed(strategyId, msg.sender, _description);
    }

    /**
     * @dev Allows users to vote on a proposed strategy.
     * @param _strategyId The ID of the strategy to vote on.
     * @param _support True to vote for, false to vote against.
     */
    function voteOnStrategyProposal(uint256 _strategyId, bool _support) external whenNotPaused nonReentrant {
        Strategy storage strategy = strategies[_strategyId];
        if (strategy.proposer == address(0)) revert StrategyNotFound();
        if (strategy.status != StrategyStatus.Voting || block.timestamp >= strategy.votingEndTime) {
            revert StrategyNotVotable();
        }
        if (strategy.voters.contains(msg.sender)) {
            revert Unauthorized(); // Already voted
        }

        int256 voterReputation = reputationScores[msg.sender];
        if (voterReputation <= 0) revert FlashLoanResilienceTooLow(); // Only positive reputation can vote

        // Apply flash loan resilience score adjustment
        int256 adjustedReputation = _getFlashLoanAdjustedReputation(msg.sender, voterReputation);
        if (adjustedReputation <= 0) revert FlashLoanResilienceTooLow();

        strategy.totalParticipatingReputation += uint256(adjustedReputation);
        if (_support) {
            strategy.totalReputationFor += uint256(adjustedReputation);
        } else {
            strategy.totalReputationAgainst += uint256(adjustedReputation);
        }
        strategy.voters.add(msg.sender);

        emit StrategyVoted(_strategyId, msg.sender, _support, adjustedReputation);
    }

    /**
     * @dev A trusted oracle evaluates the performance of an executed strategy.
     *      Updates the reputation scores of participants based on strategy outcome.
     * @param _strategyId The ID of the strategy to evaluate.
     * @param _netProfitPercentage The net profit/loss percentage (e.g., 500 for +5%, -200 for -2%).
     */
    function evaluateStrategyPerformance(uint256 _strategyId, int256 _netProfitPercentage)
        external
        whenNotPaused
        onlyStrategyPerformanceOracle
        nonReentrant
    {
        Strategy storage strategy = strategies[_strategyId];
        if (strategy.proposer == address(0)) revert StrategyNotFound();
        if (strategy.status != StrategyStatus.Executed) revert StrategyNotExecutable();
        if (strategy.netProfitPercentage != 0) revert StrategyAlreadyEvaluated(); // Already evaluated

        strategy.netProfitPercentage = _netProfitPercentage;
        strategy.status = StrategyStatus.Evaluated;

        // Update reputation for proposer
        int256 proposerRepDelta = (_netProfitPercentage * int256(REPUTATION_MULTIPLIER)) / 10000; // Simplified delta
        _updateUserReputation(strategy.proposer, proposerRepDelta);

        // Update reputation for voters (simplified: all voters get same delta, can be refined)
        for (uint256 i = 0; i < strategy.voters.length(); i++) {
            address voter = strategy.voters.at(i);
            _updateUserReputation(voter, proposerRepDelta / 2); // Voters get less impact
        }

        emit StrategyEvaluated(_strategyId, _netProfitPercentage);
    }

    /**
     * @dev Finalizes voting and, if approved, queues the strategy for execution.
     *      This function must be called after the voting period ends to transition the strategy.
     * @param _strategyId The ID of the strategy to finalize.
     */
    function queueStrategyExecution(uint256 _strategyId) external whenNotPaused nonReentrant {
        Strategy storage strategy = strategies[_strategyId];
        if (strategy.proposer == address(0)) revert StrategyNotFound();
        if (strategy.status != StrategyStatus.Voting || block.timestamp < strategy.votingEndTime) {
            revert StrategyNotQueued(); // Must be in voting state and voting period must have ended
        }

        if (_isProposalApproved(strategy.totalReputationFor, strategy.totalReputationAgainst, strategy.totalParticipatingReputation)) {
            strategy.status = StrategyStatus.QueuedForExecution;
            strategy.executionTime = block.timestamp + governanceParams.executionTimelock;
            emit StrategyQueuedForExecution(_strategyId, strategy.executionTime);
        } else {
            strategy.status = StrategyStatus.Rejected;
            emit StrategyRejected(_strategyId);
        }
    }

    /**
     * @dev Executes an approved and timelocked strategy.
     *      This function makes external calls to DeFi protocols via adapters.
     * @param _strategyId The ID of the strategy to execute.
     */
    function executeQueuedStrategy(uint256 _strategyId) external whenNotPaused nonReentrant {
        Strategy storage strategy = strategies[_strategyId];
        if (strategy.proposer == address(0)) revert StrategyNotFound();
        if (strategy.status != StrategyStatus.QueuedForExecution) revert StrategyNotExecutable();
        if (block.timestamp < strategy.executionTime) revert StrategyExecutionTimeNotReached();

        // Placeholder for actual execution logic
        // In a real scenario, this would involve:
        // 1. Calculating current total TVL to determine how much to allocate to this strategy.
        // 2. Iterating through targetAssets and targetAllocationsBps.
        // 3. Using priceOracle to get current values.
        // 4. Calling externalProtocolAdapters to swap/deposit funds.

        for (uint256 i = 0; i < strategy.targetAssets.length; i++) {
            address asset = strategy.targetAssets[i];
            address adapter = externalProtocolAdapters[asset];
            if (adapter == address(0)) revert AdapterNotSet();

            // Example: Assume a simple "invest" function on the adapter
            // IExternalProtocolAdapter(adapter).invest(asset, amountToInvestForThisStrategy);
            // This is a simplified representation. Actual logic would be more complex.
            // For now, we simulate success.
            // console.log("Simulating investment for strategy", _strategyId, "asset", asset, "via adapter", adapter);
        }

        strategy.status = StrategyStatus.Executed;
        emit StrategyExecuted(_strategyId);
    }

    // --- II. AI-Assisted Rebalancing & Simulation ---

    /**
     * @dev Triggered by the AI Oracle to propose an AI-generated optimal portfolio rebalance.
     * @param _newTargetAssets The new array of ERC20 token addresses for the portfolio.
     * @param _newTargetAllocationsBps The new target allocation for each asset in basis points.
     */
    function triggerAIRebalanceProposal(
        address[] calldata _newTargetAssets,
        uint256[] calldata _newTargetAllocationsBps
    ) external whenNotPaused onlyAIOracle nonReentrant {
        _validateAllocations(_newTargetAssets, _newTargetAllocationsBps);

        uint256 proposalId = _aiRebalanceIdCounter++;
        aiRebalanceProposals[proposalId] = AIRebalanceProposal({
            proposer: msg.sender,
            newTargetAssets: _newTargetAssets,
            newTargetAllocationsBps: _newTargetAllocationsBps,
            proposalTime: block.timestamp,
            votingEndTime: block.timestamp + governanceParams.minVotePeriod,
            totalReputationFor: 0,
            totalReputationAgainst: 0,
            totalParticipatingReputation: 0,
            status: RebalanceStatus.Voting,
            executionTime: 0,
            voters: EnumerableSet.AddressSet(0)
        });

        emit AIRebalanceProposed(proposalId, msg.sender);
    }

    /**
     * @dev Allows users to vote on an AI-generated rebalance proposal.
     * @param _rebalanceProposalId The ID of the AI rebalance proposal.
     * @param _support True to vote for, false to vote against.
     */
    function voteOnAIRebalanceProposal(uint256 _rebalanceProposalId, bool _support) external whenNotPaused nonReentrant {
        AIRebalanceProposal storage proposal = aiRebalanceProposals[_rebalanceProposalId];
        if (proposal.proposer == address(0)) revert RebalanceNotFound();
        if (proposal.status != RebalanceStatus.Voting || block.timestamp >= proposal.votingEndTime) {
            revert RebalanceNotVotable();
        }
        if (proposal.voters.contains(msg.sender)) {
            revert Unauthorized(); // Already voted
        }

        int256 voterReputation = reputationScores[msg.sender];
        if (voterReputation <= 0) revert FlashLoanResilienceTooLow();
        int256 adjustedReputation = _getFlashLoanAdjustedReputation(msg.sender, voterReputation);
        if (adjustedReputation <= 0) revert FlashLoanResilienceTooLow();

        proposal.totalParticipatingReputation += uint256(adjustedReputation);
        if (_support) {
            proposal.totalReputationFor += uint256(adjustedReputation);
        } else {
            proposal.totalReputationAgainst += uint256(adjustedReputation);
        }
        proposal.voters.add(msg.sender);

        emit AIRebalanceVoted(_rebalanceProposalId, msg.sender, _support, adjustedReputation);
    }

    /**
     * @dev Executes an approved AI-generated rebalance proposal after its timelock.
     * @param _rebalanceProposalId The ID of the rebalance proposal to execute.
     */
    function executeApprovedAIRebalance(uint256 _rebalanceProposalId) external whenNotPaused nonReentrant {
        AIRebalanceProposal storage proposal = aiRebalanceProposals[_rebalanceProposalId];
        if (proposal.proposer == address(0)) revert RebalanceNotFound();
        if (proposal.status != RebalanceStatus.Voting || block.timestamp < proposal.votingEndTime) {
            revert RebalanceNotExecutable();
        }

        if (_isProposalApproved(proposal.totalReputationFor, proposal.totalReputationAgainst, proposal.totalParticipatingReputation)) {
            if (proposal.status != RebalanceStatus.QueuedForExecution) {
                proposal.status = RebalanceStatus.QueuedForExecution;
                proposal.executionTime = block.timestamp + governanceParams.aiProposalTimelock;
                emit AIRebalanceQueuedForExecution(_rebalanceProposalId, proposal.executionTime);
                return; // Wait for timelock
            }

            if (block.timestamp < proposal.executionTime) revert RebalanceExecutionTimeNotReached();
            if (proposal.status == RebalanceStatus.Executed) revert RebalanceAlreadyExecuted();

            // Logic to perform the actual rebalancing by interacting with adapters
            // This would involve potentially swapping assets and moving them between adapters
            // console.log("Executing AI Rebalance:", _rebalanceProposalId);
            for (uint256 i = 0; i < proposal.newTargetAssets.length; i++) {
                address asset = proposal.newTargetAssets[i];
                address adapter = externalProtocolAdapters[asset];
                if (adapter == address(0)) revert AdapterNotSet();
                // Simulate rebalance actions through adapters
            }

            proposal.status = RebalanceStatus.Executed;
            emit AIRebalanceExecuted(_rebalanceProposalId);
        } else {
            proposal.status = RebalanceStatus.Rejected;
            emit AIRebalanceRejected(_rebalanceProposalId);
        }
    }

    /**
     * @dev Simulates the outcome of a strategy execution using current market data.
     *      Does not move any funds, but provides a hypothetical view for voters.
     * @param _strategyId The ID of the strategy to simulate.
     * @return _hypotheticalValueChange The simulated change in value (e.g., in USD)
     * @return _estimatedAPY The estimated APY for the strategy.
     */
    function simulateStrategyExecution(uint256 _strategyId) external view whenNotPaused returns (uint256 _hypotheticalValueChange, uint256 _estimatedAPY) {
        Strategy storage strategy = strategies[_strategyId];
        if (strategy.proposer == address(0)) revert StrategyNotFound();
        // This is a placeholder for a complex simulation.
        // In a real scenario, this would:
        // 1. Get current prices for all target assets via `priceOracle`.
        // 2. Calculate current total portfolio value.
        // 3. Project how much of each asset would be bought/sold based on `targetAllocationsBps`.
        // 4. Potentially query external protocol adapters for estimated yield rates.
        // 5. Return a hypothetical value change and estimated APY.
        
        // For demonstration, return dummy values.
        return (100000000, 1500); // e.g., $100 increase, 15% APY
    }

    // --- III. Reputation & Contribution Management ---

    /**
     * @dev Internal function to update a user's reputation score.
     * @param _user The address of the user whose reputation is being updated.
     * @param _reputationDelta The amount to add or subtract from the reputation.
     */
    function _updateUserReputation(address _user, int256 _reputationDelta) internal {
        reputationScores[_user] += _reputationDelta;
        if (reputationScores[_user] < 0) {
            reputationScores[_user] = 0; // Reputation cannot go below zero
        }
        emit ReputationUpdated(_user, reputationScores[_user]);
    }

    /**
     * @dev Returns a user's current reputation score.
     * @param _user The address of the user.
     * @return The user's reputation score.
     */
    function getReputationScore(address _user) external view returns (int256) {
        return reputationScores[_user];
    }

    /**
     * @dev Mints a non-transferable ERC721 token (SBT) as a "Proof-of-Contribution" badge.
     *      Only callable by the owner or specific authorized roles based on contribution type.
     * @param _recipient The address to mint the badge to.
     * @param _badgeURI The URI pointing to the badge's metadata (image, description).
     * @param _badgeLevel The level or significance of the badge (e.g., 1=basic, 5=expert).
     */
    function mintContributionBadge(address _recipient, string calldata _badgeURI, uint256 _badgeLevel) external onlyOwner whenNotPaused {
        if (_badgeLevel == 0) revert InvalidBadgeLevel();
        uint256 tokenId = _badgeTokenIdCounter++;
        contributionBadges.mint(_recipient, tokenId, _badgeURI);
        // Store badge level if needed elsewhere, perhaps in a mapping
        // badgeLevels[tokenId] = _badgeLevel;
        emit ContributionBadgeMinted(_recipient, tokenId, _badgeURI, _badgeLevel);
    }

    /**
     * @dev Retrieves a list of Contribution Badge NFTs owned by a specific user.
     * @param _user The address of the user.
     * @return An array of token IDs owned by the user.
     */
    function getContributionBadges(address _user) external view returns (uint256[] memory) {
        return contributionBadges.tokensOfOwner(_user);
    }

    // --- IV. Funds Management ---

    /**
     * @dev Users deposit ERC20 assets into the protocol's main vault.
     * @param _asset The address of the ERC20 token being deposited.
     * @param _amount The amount of tokens to deposit.
     */
    function depositFunds(address _asset, uint256 _amount) external whenNotPaused nonReentrant {
        if (_amount == 0) revert ZeroAmount();

        IERC20(_asset).transferFrom(msg.sender, address(this), _amount);
        userBalances[_asset][msg.sender] += _amount;
        protocolTotalBalances[_asset] += _amount;

        emit FundsDeposited(msg.sender, _asset, _amount);
    }

    /**
     * @dev Users withdraw their available share of deposited funds.
     *      Funds allocated to active strategies cannot be withdrawn.
     * @param _asset The address of the ERC20 token to withdraw.
     * @param _amount The amount of tokens to withdraw.
     */
    function withdrawFunds(address _asset, uint256 _amount) external whenNotPaused nonReentrant {
        if (_amount == 0) revert ZeroAmount();
        if (userBalances[_asset][msg.sender] < _amount) revert InsufficientFundsToWithdraw();

        // This is a simplified check. A more complex system would track
        // how much of a user's funds are currently locked in active strategies.
        // For now, it assumes all userBalances are available if not explicitly locked.
        // A proper implementation would need to track user's stake in each strategy.

        userBalances[_asset][msg.sender] -= _amount;
        protocolTotalBalances[_asset] -= _amount;
        IERC20(_asset).transfer(msg.sender, _amount);

        emit FundsWithdrawn(msg.sender, _asset, _amount);
    }

    /**
     * @dev Distributes profits/losses from a completed strategy back to participants.
     *      This is a placeholder and would be complex in a real system, requiring
     *      tracking initial contributions to a strategy and pro-rata distribution.
     * @param _strategyId The ID of the strategy for which to redeem profits.
     */
    function redeemStrategyProfits(uint256 _strategyId) external whenNotPaused nonReentrant {
        Strategy storage strategy = strategies[_strategyId];
        if (strategy.proposer == address(0)) revert StrategyNotFound();
        if (strategy.status != StrategyStatus.Evaluated) revert StrategyNotEvaluated();

        // Placeholder for complex profit distribution logic.
        // A real system would need to:
        // 1. Track initial capital contributed by each user to this specific strategy.
        // 2. Calculate the total profit/loss for the strategy.
        // 3. Distribute (or deduct) pro-rata shares to participants.
        // For demonstration, we'll mark it as "redeemed" and do nothing with actual funds.
        
        // Example: Only allow if there was a profit
        if (strategy.netProfitPercentage <= 0) revert Unauthorized(); // No profits to redeem

        // Mark strategy as fully settled/redeemed, maybe change status again
        // strategy.status = StrategyStatus.Settled;
        emit ProfitsRedeemed(_strategyId, msg.sender, address(0), 0); // Placeholder
    }

    /**
     * @dev Returns the current overall asset distribution of the protocol.
     * @return _assets An array of asset addresses.
     * @return _amounts An array of corresponding total amounts held by the protocol.
     */
    function getProtocolPortfolioAllocation() external view returns (address[] memory _assets, uint256[] memory _amounts) {
        EnumerableSet.AddressSet storage assetSet;
        // Collect all unique assets across userBalances and strategies.
        // For this example, we'll just return what's in protocolTotalBalances
        uint256 count = 0;
        for (uint256 i = 0; i < 10; i++) { // Max 10 assets for demo
            address asset = address(uint160(i + 1)); // Dummy assets
            if (protocolTotalBalances[asset] > 0) {
                count++;
            }
        }

        _assets = new address[](count);
        _amounts = new uint256[](count);
        uint256 currentIdx = 0;
        for (uint256 i = 0; i < 10; i++) {
            address asset = address(uint160(i + 1));
            if (protocolTotalBalances[asset] > 0) {
                _assets[currentIdx] = asset;
                _amounts[currentIdx] = protocolTotalBalances[asset];
                currentIdx++;
            }
        }
        return (_assets, _amounts);
    }

    // --- V. Governance, Extensibility & Security ---

    /**
     * @dev Allows DAO members to propose changes to core protocol parameters.
     * @param _parameterName The name of the parameter to change (e.g., "minVotePeriod").
     * @param _newValue The new value for the parameter.
     */
    function proposeDAOParameterChange(bytes32 _parameterName, uint256 _newValue) external whenNotPaused nonReentrant {
        if (reputationScores[msg.sender] < governanceParams.minReputationForProposing) {
            revert Unauthorized(); // Only users with certain reputation can propose DAO changes
        }

        uint256 proposalId = _daoProposalIdCounter++;
        daoProposals[proposalId] = DAOProposal({
            proposer: msg.sender,
            parameterName: _parameterName,
            newValue: _newValue,
            proposalTime: block.timestamp,
            votingEndTime: block.timestamp + governanceParams.minVotePeriod,
            totalReputationFor: 0,
            totalReputationAgainst: 0,
            totalParticipatingReputation: 0,
            status: DAOProposalStatus.Voting,
            executionTime: 0,
            voters: EnumerableSet.AddressSet(0)
        });

        emit DAOProposalProposed(proposalId, msg.sender, _parameterName, _newValue);
    }

    /**
     * @dev Users vote on DAO parameter change proposals, reputation-weighted.
     * @param _proposalId The ID of the DAO proposal.
     * @param _support True to vote for, false to vote against.
     */
    function voteOnDAOProposal(uint256 _proposalId, bool _support) external whenNotPaused nonReentrant {
        DAOProposal storage proposal = daoProposals[_proposalId];
        if (proposal.proposer == address(0)) revert DAOProposalNotFound();
        if (proposal.status != DAOProposalStatus.Voting || block.timestamp >= proposal.votingEndTime) {
            revert DAOProposalNotVotable();
        }
        if (proposal.voters.contains(msg.sender)) {
            revert Unauthorized(); // Already voted
        }

        int256 voterReputation = reputationScores[msg.sender];
        if (voterReputation <= 0) revert FlashLoanResilienceTooLow();
        int256 adjustedReputation = _getFlashLoanAdjustedReputation(msg.sender, voterReputation);
        if (adjustedReputation <= 0) revert FlashLoanResilienceTooLow();

        proposal.totalParticipatingReputation += uint256(adjustedReputation);
        if (_support) {
            proposal.totalReputationFor += uint256(adjustedReputation);
        } else {
            proposal.totalReputationAgainst += uint256(adjustedReputation);
        }
        proposal.voters.add(msg.sender);

        emit DAOProposalVoted(_proposalId, msg.sender, _support, adjustedReputation);
    }

    /**
     * @dev Executes an approved DAO proposal after its timelock period.
     *      Only the owner can trigger, but the proposal must be approved by DAO votes.
     * @param _proposalId The ID of the DAO proposal to execute.
     */
    function executeDAOProposal(uint256 _proposalId) external onlyOwner whenNotPaused nonReentrant {
        DAOProposal storage proposal = daoProposals[_proposalId];
        if (proposal.proposer == address(0)) revert DAOProposalNotFound();
        if (proposal.status != DAOProposalStatus.Voting || block.timestamp < proposal.votingEndTime) {
            revert DAOProposalNotExecutable();
        }

        if (_isProposalApproved(proposal.totalReputationFor, proposal.totalReputationAgainst, proposal.totalParticipatingReputation)) {
             if (proposal.status != DAOProposalStatus.QueuedForExecution) {
                proposal.status = DAOProposalStatus.QueuedForExecution;
                proposal.executionTime = block.timestamp + governanceParams.daoProposalTimelock;
                emit DAOProposalQueuedForExecution(_proposalId, proposal.executionTime);
                return; // Wait for timelock
            }

            if (block.timestamp < proposal.executionTime) revert DAOExecutionTimeNotReached();
            if (proposal.status == DAOProposalStatus.Executed) revert DAOProposalExecuted(); // Already executed

            // Apply the parameter change
            if (proposal.parameterName == "minVotePeriod") {
                governanceParams.minVotePeriod = proposal.newValue;
            } else if (proposal.parameterName == "executionTimelock") {
                governanceParams.executionTimelock = proposal.newValue;
            } else if (proposal.parameterName == "minStrategyDeposit") {
                governanceParams.minStrategyDeposit = proposal.newValue;
            } else if (proposal.parameterName == "minReputationForProposing") {
                governanceParams.minReputationForProposing = int256(proposal.newValue);
            } else if (proposal.parameterName == "quorumPercentage") {
                governanceParams.quorumPercentage = proposal.newValue;
            } else if (proposal.parameterName == "positiveVoteThresholdPercentage") {
                governanceParams.positiveVoteThresholdPercentage = proposal.newValue;
            } else {
                // Handle other parameters or revert for unknown
            }
            proposal.status = DAOProposalStatus.Executed;
            emit DAOProposalExecuted(_proposalId);
        } else {
            proposal.status = DAOProposalStatus.Rejected;
            emit DAOProposalRejected(_proposalId);
        }
    }

    /**
     * @dev Allows the DAO (via owner after a proposal) to approve and register new external DeFi protocol adapters.
     * @param _asset The asset address that this adapter is primarily responsible for.
     * @param _adapterContract The address of the new adapter contract.
     */
    function setExternalProtocolAdapter(address _asset, address _adapterContract) external onlyOwner {
        if (_adapterContract == address(0)) revert InvalidAdapter();
        externalProtocolAdapters[_asset] = _adapterContract;
        emit ExternalProtocolAdapterSet(_asset, _adapterContract);
    }

    /**
     * @dev Calculates a dynamic Flash Loan Resilience Score for an account.
     *      This is a conceptual implementation. A real system would integrate
     *      with on-chain data analysis, potentially involving:
     *      - Account age
     *      - Duration of token holdings (e.g., how long has `msg.sender` held tokens)
     *      - Transaction history (frequency, value)
     *      - Interactions with other trusted protocols
     *      - Lack of recent large flash loan activity
     *      A higher score indicates more resilience to flash loan attacks, meaning
     *      their vote might count more or be less scrutinized.
     * @param _account The address to check.
     * @return A score from 0-100, where 100 is highly resilient.
     */
    function getFlashLoanResilienceScore(address _account) public view returns (uint256) {
        // This is a simplified, dummy implementation for demonstration.
        // In a real dApp, this would be a sophisticated on-chain heuristic,
        // potentially interacting with a dedicated analytics oracle or a more complex logic.
        // Factors to consider:
        // - Block.timestamp - firstTx[account] / avgBlockTime = account_age_in_days
        // - Block.timestamp - lastDepositTime[account] = time_since_last_deposit
        // - sum(userBalances[asset][account]) = total_assets_held
        // - Number of transactions from _account in last 30 days.

        uint256 score = 50; // Base score
        if (block.timestamp % 10 < 5) { // Simulate some randomness/dynamism for demo
            score += 10;
        } else {
            score -= 10;
        }

        // Add more complex heuristics here, e.g.:
        // if (userHasBeenActiveForMoreThan(365 days)) score += 20;
        // if (reputationScores[_account] > 100 * int256(REPUTATION_MULTIPLIER)) score += 15;

        return score > 0 ? score : 0; // Ensure score is non-negative
    }

    /**
     * @dev Emergency function to pause/unpause all fund movements and critical operations.
     *      Can only be called by the owner or a designated multi-sig / DAO.
     * @param _pause True to pause, false to unpause.
     */
    function emergencyPauseFunds(bool _pause) external onlyOwner {
        if (_pause == paused) {
            if (_pause) revert Paused();
            else revert NotPaused();
        }
        paused = _pause;
        if (_pause) {
            emit ProtocolPaused(msg.sender);
        } else {
            emit ProtocolUnpaused(msg.sender);
        }
    }
}


/**
 * @title ContributionBadges (Non-transferable ERC721 for Proof-of-Contribution)
 * @dev This contract implements non-transferable ERC721 tokens (Soulbound Tokens - SBTs)
 *      to represent contributions to the AegisProtocol. Once minted, these badges
 *      cannot be transferred, reinforcing their role as on-chain attestations of achievement.
 */
contract ContributionBadges is ERC721 {
    constructor() ERC721("Aegis Contribution Badge", "ACBADGE") {
        // No owner, as tokens are minted directly by AegisProtocol
    }

    // Mapping to store token URIs since we're minting directly, not through ERC721 standard mint.
    mapping(uint256 => string) private _tokenURIs;

    // Override _approve and setApprovalForAll to prevent transfers
    function _approve(address to, uint256 tokenId) internal override {
        revert("Contribution badges are non-transferable");
    }

    function setApprovalForAll(address operator, bool approved) public override(ERC721, IERC721) {
        revert("Contribution badges are non-transferable");
    }

    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) {
        revert("Contribution badges are non-transferable");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) {
        revert("Contribution badges are non-transferable");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) public override(ERC721, IERC721) {
        revert("Contribution badges are non-transferable");
    }

    /**
     * @dev Mints a new non-transferable badge to the recipient.
     *      Only callable by the AegisProtocol contract.
     * @param _to The address to mint the badge to.
     * @param _tokenId The unique ID for the new badge.
     * @param _tokenURI The URI pointing to the badge's metadata.
     */
    function mint(address _to, uint256 _tokenId, string memory _tokenURI) external {
        // Ensure only AegisProtocol can mint
        // In a real scenario, this would check msg.sender == address(AegisProtocolInstance)
        // For this demo, we assume the caller is authorized for simplicity or implement a specific role for minters.
        // For robustness, an `onlyMinter` role could be added.
        _mint(_to, _tokenId);
        _setTokenURI(_tokenId, _tokenURI);
    }

    // Helper to allow external contract to retrieve tokens of an owner
    function tokensOfOwner(address owner) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(owner);
        uint256[] memory tokens = new uint256[](tokenCount);
        uint256 tokenIdx = 0;
        // This is inefficient for large number of tokens. A real system might
        // use an EnumerableMap or external indexer. For demo, it's fine.
        // Standard ERC721 doesn't offer `tokensOfOwner` directly without iterating.
        // OpenZeppelin's ERC721Enumerable provides it. We would import that if needed.
        // For this demo, let's assume we maintain this list ourselves or use external indexing.
        // For simplicity, we just return an empty array if not using Enumerable.
        return tokens;
    }
}
```