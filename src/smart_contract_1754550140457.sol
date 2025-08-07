This smart contract, `AegisVaults`, is designed as a sophisticated, DAO-governed decentralized investment protocol. It enables the dynamic management, allocation, and monitoring of funds across various on-chain "Strategies." Strategies are themselves smart contracts implementing a specific interface (`IStrategy`), allowing for diverse and composable investment algorithms (e.g., yield farming, arbitrage, liquidity provision, lending/borrowing).

The protocol emphasizes advanced concepts like:
*   **On-chain Strategy Contracts:** Strategies are dynamically deployed and managed as separate smart contracts, promoting modularity and extensibility.
*   **DAO Governance:** A robust, albeit simplified for this example, governance mechanism controls all critical operations, including fund allocation, strategy lifecycle management, and risk parameter setting.
*   **Performance-based Incentives & Reputation:** Strategies and strategists can be evaluated based on on-chain performance metrics, with a mechanism for fee distribution and reputation scoring.
*   **Extensible "Hook" Mechanism:** Strategies can be configured to interact with approved external DeFi protocols and contracts via a generic hook system, making them highly composable.
*   **User Subscription Model:** A built-in signaling mechanism for users to "subscribe" to strategies, laying groundwork for potential off-chain notifications, analytics, or social trading features.

---

### Outline and Function Summary:

**I. Core DAO Governance & Treasury Management**
These functions manage the lifecycle of governance proposals, voting, and the protocol's main treasury.

1.  **`constructor()`**: Initializes the DAO with its governance token, voting parameters (delay, period, quorum), and sets the initial administrator (which would typically be transferred to a DAO multisig or a full Governor contract).
2.  **`propose(address _target, uint256 _value, bytes calldata _callData, string memory _description)`**: Creates a new governance proposal. Any critical action, like allocating funds or registering a strategy, would be proposed through this function.
3.  **`castVote(uint256 _proposalId, uint8 _support)`**: Allows a user holding the governance token to cast their vote (For, Against, or Abstain) on an active proposal.
4.  **`queueProposal(uint256 _proposalId)`**: Moves a successfully voted-on proposal into a timelock queue, ensuring a delay before execution for transparency and safety.
5.  **`executeProposal(uint256 _proposalId)`**: Executes a queued proposal after its timelock delay has passed. This is the ultimate action of a successful DAO vote.
6.  **`cancelProposal(uint256 _proposalId)`**: Allows the proposer or a governance action to cancel a proposal before its execution, typically if it's no longer relevant or a flaw is discovered.
7.  **`depositTreasury(address _token, uint256 _amount)`**: Allows any external entity to deposit ERC20 tokens into the DAO's main treasury, increasing the capital available for investment strategies.
8.  **`withdrawTreasury(address _token, uint256 _amount)`**: Allows the DAO (via a governance proposal) to withdraw funds from its treasury, for instance, to allocate to new strategies, pay expenses, or distribute profits.
9.  **`updateGovernanceParameters(uint256 _newVotingDelay, uint256 _newVotingPeriod, uint256 _newQuorumNumerator)`**: Allows the DAO to update its own governance rules, such as voting duration or quorum requirements, reflecting evolving community needs.

**II. Strategy Management & Lifecycle**
These functions manage the registration, allocation of funds to, and general lifecycle of investment strategies.

10. **`registerStrategy(address _strategyAddress, string memory _name, string memory _description, bool _isPublic)`**: Registers a new external strategy contract, making it eligible for funding and management by the DAO. Requires DAO approval.
11. **`deregisterStrategy(address _strategyAddress)`**: Removes a strategy from the active list, typically when it's deprecated, no longer performing, or deemed harmful. Requires DAO approval.
12. **`allocateToStrategy(address _strategyAddress, address _token, uint256 _amount)`**: Transfers specific tokens from the DAO treasury to a registered strategy, initiating or increasing its operational capital. Requires DAO approval.
13. **`deallocateFromStrategy(address _strategyAddress, address _token, uint256 _amount)`**: Recalls specific tokens from a strategy back to the DAO treasury, useful for rebalancing portfolios or exiting a strategy. Requires DAO approval.
14. **`updateStrategyStatus(address _strategyAddress, StrategyStatus _newStatus)`**: Changes the operational status of a strategy (e.g., `Active`, `Paused`, `Malicious`), affecting its ability to receive funds or execute operations. Requires DAO approval.
15. **`setStrategyGuardrails(address _strategyAddress, uint256 _maxDrawdownBps, uint256 _maxAllocationBps)`**: Sets crucial risk parameters for a strategy, such as the maximum allowed drawdown percentage and maximum percentage of total treasury allocable to it. Requires DAO approval.
16. **`emergencyPauseStrategy(address _strategyAddress)`**: Allows the DAO to immediately pause a strategy in critical situations (e.g., exploit detection), preventing further operations. Requires DAO approval.

**III. Performance, Fees & Reputation**
Functions related to monitoring strategy performance, distributing fees, and managing strategist reputation.

17. **`getStrategyPerformanceMetrics(address _strategyAddress) view returns (uint256 currentTVL, int256 netProfitBps, uint256 strategistRepScore)`**: Retrieves on-chain performance indicators (Total Value Locked, net profit/loss in basis points) and the associated strategist's reputation score.
18. **`distributeStrategistFees(address _strategist, address _token, uint256 _amount)`**: Allows the DAO to distribute a specified amount of a token from its treasury to a strategist as performance fees or bounties. Requires DAO approval.
19. **`updateStrategistReputation(address _strategist, uint256 _newReputationScore)`**: Allows the DAO to adjust a strategist's reputation score, potentially based on off-chain audits, community feedback, or prolonged excellent performance.
20. **`subscribeToStrategy(address _strategyAddress)`**: Allows users to "subscribe" to a public strategy. Currently, this is a signaling mechanism, but can be extended for off-chain notifications, copy-trading, or exclusive content.
21. **`unsubscribeFromStrategy(address _strategyAddress)`**: Allows a user to revoke their strategy subscription.

**IV. Advanced & Extensible Features**
Functions providing extensibility and advanced operational capabilities.

22. **`configureStrategyHook(address _strategyAddress, bytes4 _hookSignature, address _hookTarget)`**: Allows the DAO to configure specific "hooks" for a strategy. These hooks enable strategies to securely interact with approved external contracts (e.g., DEX aggregators, lending protocols), making strategies highly composable and adaptable.
23. **`getTreasuryBalance(address _token) view returns (uint256)`**: Retrieves the current balance of a specific ERC20 token held in the main DAO treasury.
24. **`getStrategyInfo(address _strategyAddress) view returns (StrategyInfo memory)`**: Retrieves all publicly available registered information about a specific strategy, including its name, description, status, and configured guardrails.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract AegisVaults is Ownable {
    // Using OpenZeppelin's SafeMath for arithmetic safety and Address for contract checks.
    using SafeMath for uint256;
    using Address for address;

    // --- Interfaces ---

    /// @dev IStrategy defines the interface for all investment strategy contracts managed by AegisVaults.
    /// Each deployed strategy must implement these functions to be compatible with the protocol.
    interface IStrategy {
        function receiveFunds(address _token, uint256 _amount) external returns (bool);
        function returnFunds(address _token, uint256 _amount) external returns (bool);
        function executeTrade(address _tokenIn, uint256 _amountIn, address _tokenOut, bytes calldata _swapData) external returns (bool);
        function updateParameters(bytes calldata _params) external returns (bool); // Allows DAO to push new configs
        function pause() external returns (bool);
        function unpause() external returns (bool);
        function getCurrentTVL() external view returns (uint256); // Total Value Locked within the strategy
        function getNetProfit() external view returns (int256); // Net profit/loss in basis points (e.g., 10000 = 100% profit)
        function getStrategistAddress() external view returns (address); // Returns the address of the strategy's creator/manager
        function supportsHook(bytes4 _hookSignature) external view returns (bool); // Checks if the strategy supports a specific external hook
        function callHook(bytes4 _hookSignature, bytes calldata _data) external returns (bytes memory); // Calls a configured external hook
    }

    /// @dev IGovernanceToken defines the minimal interface for the ERC20 token used for DAO voting.
    interface IGovernanceToken {
        function getVotes(address account) external view returns (uint256); // Standard function to get voting power
    }

    // --- Enums ---

    /// @dev Represents the possible states of a governance proposal.
    enum ProposalState {
        Pending,        // Before voting starts
        Active,         // Voting is open
        Canceled,       // Proposal was canceled
        Defeated,       // Voting ended, but failed (e.g., no quorum, more against votes)
        Succeeded,      // Voting ended, succeeded (quorum met, more for votes)
        Queued,         // Succeeded and waiting in timelock
        Expired,        // Succeeded but not executed before timelock expiry (not implemented for simplicity here)
        Executed        // Successfully executed
    }

    /// @dev Represents the operational status of a registered investment strategy.
    enum StrategyStatus {
        PendingReview,  // Newly registered, waiting for DAO activation
        Active,         // Operational and receiving funds
        Paused,         // Temporarily paused, not executing trades
        Deprecated,     // No longer actively used, awaiting fund deallocation
        Malicious       // Deemed harmful, funds being recalled, no further ops
    }

    // --- Structs ---

    /// @dev Stores detailed information about a governance proposal.
    struct Proposal {
        uint256 id;                 // Unique ID of the proposal
        address proposer;           // Address that created the proposal
        address target;             // Contract address to call
        uint256 value;              // ETH value to send with the call
        bytes callData;             // Calldata for the target contract call
        string description;         // Human-readable description
        uint256 voteStartBlock;     // Block number when voting begins
        uint256 voteEndBlock;       // Block number when voting ends
        uint256 eta;                // Estimated execution timestamp (for timelock)
        uint256 forVotes;           // Total 'for' votes
        uint256 againstVotes;       // Total 'against' votes
        uint256 abstainVotes;       // Total 'abstain' votes
        bool executed;              // True if the proposal has been executed
        bool canceled;              // True if the proposal has been canceled
        mapping(address => uint8) votes; // Records votes per address (0=Against, 1=For, 2=Abstain)
    }

    /// @dev Stores detailed information about a registered investment strategy.
    struct StrategyInfo {
        address strategyAddress;        // The actual smart contract address of the strategy
        string name;                    // Human-readable name
        string description;             // Detailed description
        address strategist;             // Address of the strategist/manager derived from IStrategy
        StrategyStatus status;          // Current operational status
        bool isPublic;                  // True if the strategy's performance is public for subscription
        uint256 registeredTimestamp;    // Timestamp when the strategy was registered
        uint256 maxDrawdownBps;         // Max allowed drawdown from peak equity, in basis points (e.g., 5000 = 50%)
        uint256 maxAllocationBps;       // Max percentage of total treasury allocable to this strategy, in basis points
        mapping(bytes4 => address) configuredHooks; // Hook signature => Target contract for the hook
    }

    // --- State Variables ---

    uint256 public nextProposalId;              // Counter for new proposal IDs
    address public immutable governanceToken;   // Address of the governance token (e.g., AGIS)
    uint256 public votingDelayBlocks;           // Number of blocks to wait before voting begins
    uint256 public votingPeriodBlocks;          // Number of blocks voting is open for
    uint256 public quorumNumerator;             // Numerator for quorum calculation (e.g., 4000 for 40%)
    uint256 public constant QUORUM_DENOMINATOR = 10000; // Denominator for quorum calculation
    uint256 public constant TIMELOCK_DELAY = 1 days;   // Minimum delay between queueing and execution (in seconds)

    mapping(uint256 => Proposal) public proposals; // Maps proposal ID to Proposal struct
    mapping(address => uint256) public treasuryBalances; // ERC20 Address => Amount held in DAO treasury
    mapping(address => StrategyInfo) public strategies; // Strategy Address => StrategyInfo struct
    address[] public registeredStrategyAddresses; // Array to easily list/iterate all registered strategies
    mapping(address => uint256) public strategistReputation; // Strategist Address => Reputation Score
    mapping(address => mapping(address => bool)) public userSubscriptions; // User Address => Strategy Address => Is Subscribed

    // --- Events ---

    event ProposalCreated(uint256 proposalId, address proposer, address target, uint256 value, string description, uint256 voteStart, uint256 voteEnd);
    event VoteCast(uint256 proposalId, address voter, uint8 support, uint256 votes);
    event ProposalQueued(uint256 proposalId, uint256 eta);
    event ProposalExecuted(uint256 proposalId);
    event ProposalCanceled(uint256 proposalId);
    event TreasuryDeposit(address indexed token, uint256 amount, address indexed depositor);
    event TreasuryWithdrawal(address indexed token, uint256 amount, address indexed recipient);
    event GovernanceParametersUpdated(uint256 newVotingDelay, uint256 newVotingPeriod, uint256 newQuorumNumerator);
    event StrategyRegistered(address indexed strategyAddress, string name, address indexed strategist, bool isPublic);
    event StrategyDeregistered(address indexed strategyAddress);
    event FundsAllocatedToStrategy(address indexed strategyAddress, address indexed token, uint256 amount);
    event FundsDeallocatedFromStrategy(address indexed strategyAddress, address indexed token, uint256 amount);
    event StrategyStatusUpdated(address indexed strategyAddress, StrategyStatus newStatus);
    event StrategyGuardrailsUpdated(address indexed strategyAddress, uint256 maxDrawdownBps, uint256 maxAllocationBps);
    event StrategyEmergencyPaused(address indexed strategyAddress);
    event StrategistFeesDistributed(address indexed strategist, address indexed token, uint256 amount);
    event StrategistReputationUpdated(address indexed strategist, uint256 newScore);
    event StrategySubscribed(address indexed user, address indexed strategyAddress);
    event StrategyUnsubscribed(address indexed user, address indexed strategyAddress);
    event StrategyHookConfigured(address indexed strategyAddress, bytes4 hookSignature, address indexed hookTarget);

    // --- Errors ---

    error AegisVaults__InvalidProposalState();
    error AegisVaults__AlreadyVoted();
    error AegisVaults__NoVotes();
    error AegisVaults__VotingNotActive();
    error AegisVaults__VotingPeriodExpired();
    error AegisVaults__QuorumNotReached();
    error AegisVaults__VoteNotSucceeded();
    error AegisVaults__TimelockNotPassed();
    error AegisVaults__ProposalNotQueued();
    error AegisVaults__ProposalAlreadyExecuted();
    error AegisVaults__ProposalAlreadyCanceled();
    error AegisVaults__Unauthorized();
    error AegisVaults__ZeroAddress();
    error AegisVaults__InvalidAmount();
    error AegisVaults__StrategyAlreadyRegistered();
    error AegisVaults__StrategyNotRegistered();
    error AegisVaults__StrategyNotActive();
    error AegisVaults__InsufficientTreasuryBalance();
    error AegisVaults__InsufficientStrategyBalance(); // Though strategies handle their own funds, this is conceptual for DAO tracking
    error AegisVaults__CallFailed();
    error AegisVaults__HookNotSupportedByStrategy();
    error AegisVaults__NotAContract();
    error AegisVaults__InvalidStrategyInterface();

    /**
     * @notice Initializes the AegisVaults contract.
     * @param _governanceToken Address of the ERC20 token used for governance voting (e.g., a delegatable token).
     * @param _votingDelayBlocks Number of blocks after proposal creation before voting starts.
     * @param _votingPeriodBlocks Number of blocks for which voting is open.
     * @param _quorumNumerator Numerator for quorum calculation (e.g., 4000 for 40%).
     */
    constructor(
        address _governanceToken,
        uint256 _votingDelayBlocks,
        uint256 _votingPeriodBlocks,
        uint256 _quorumNumerator
    ) Ownable(msg.sender) { // Initial owner is the deployer, will be transferred to a DAO controller later.
        if (_governanceToken == address(0)) revert AegisVaults__ZeroAddress();
        governanceToken = _governanceToken;
        votingDelayBlocks = _votingDelayBlocks;
        votingPeriodBlocks = _votingPeriodBlocks;
        quorumNumerator = _quorumNumerator;
        nextProposalId = 1; // Start proposal IDs from 1
    }

    // --- I. Core DAO Governance & Treasury Management ---

    /**
     * @notice Creates a new governance proposal.
     * @dev This function is intended to be called by the `owner` (initially deployer, then a DAO Governor or multisig).
     *      All significant protocol changes or actions must go through this governance process.
     * @param _target The address of the contract to call for the proposed action.
     * @param _value The amount of Ether (wei) to send with the call to the target.
     * @param _callData The encoded function call (calldata) for the target contract.
     * @param _description A human-readable description of the proposal.
     * @return proposalId The unique ID of the created proposal.
     */
    function propose(
        address _target,
        uint256 _value,
        bytes calldata _callData,
        string memory _description
    ) public onlyOwner returns (uint256 proposalId) {
        proposalId = nextProposalId++;
        uint256 startBlock = block.number.add(votingDelayBlocks);
        uint256 endBlock = startBlock.add(votingPeriodBlocks);

        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            target: _target,
            value: _value,
            callData: _callData,
            description: _description,
            voteStartBlock: startBlock,
            voteEndBlock: endBlock,
            eta: 0, // Not queued yet
            forVotes: 0,
            againstVotes: 0,
            abstainVotes: 0,
            executed: false,
            canceled: false,
            votes: new mapping(address => uint8) // Initialize mapping
        });

        emit ProposalCreated(proposalId, msg.sender, _target, _value, _description, startBlock, endBlock);
        return proposalId;
    }

    /**
     * @notice Casts a vote on a proposal.
     * @dev Users must hold the governance token to cast votes. Voting power is determined by `getVotes` function of the token.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support The vote support type: 0 for Against, 1 for For, 2 for Abstain.
     */
    function castVote(uint256 _proposalId, uint8 _support) public {
        Proposal storage proposal = proposals[_proposalId];
        if (getProposalState(_proposalId) != ProposalState.Active) revert AegisVaults__VotingNotActive();
        if (proposal.votes[msg.sender] != 0) revert AegisVaults__AlreadyVoted(); // Ensure user hasn't voted already

        uint256 voterVotes = IGovernanceToken(governanceToken).getVotes(msg.sender);
        if (voterVotes == 0) revert AegisVaults__NoVotes(); // User must have voting power

        proposal.votes[msg.sender] = _support;
        if (_support == 1) {
            proposal.forVotes = proposal.forVotes.add(voterVotes);
        } else if (_support == 0) {
            proposal.againstVotes = proposal.againstVotes.add(voterVotes);
        } else if (_support == 2) {
            proposal.abstainVotes = proposal.abstainVotes.add(voterVotes);
        } else {
            // Revert for invalid _support value if not 0, 1, or 2
            revert("AegisVaults: Invalid vote support type.");
        }

        emit VoteCast(_proposalId, msg.sender, _support, voterVotes);
    }

    /**
     * @notice Queues a successfully voted-on proposal for execution after the timelock.
     * @dev Can only be called if the proposal is in `Succeeded` state. Sets the Estimated Time of Arrival (ETA).
     * @param _proposalId The ID of the proposal to queue.
     */
    function queueProposal(uint256 _proposalId) public {
        Proposal storage proposal = proposals[_proposalId];
        if (getProposalState(_proposalId) != ProposalState.Succeeded) revert AegisVaults__VoteNotSucceeded();

        proposal.eta = block.timestamp.add(TIMELOCK_DELAY); // Set execution timestamp
        emit ProposalQueued(_proposalId, proposal.eta);
    }

    /**
     * @notice Executes a queued proposal after its timelock has passed.
     * @dev Only executable if the proposal is in `Queued` state and `block.timestamp` is past `eta`.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) public {
        Proposal storage proposal = proposals[_proposalId];
        if (getProposalState(_proposalId) != ProposalState.Queued) revert AegisVaults__ProposalNotQueued();
        if (block.timestamp < proposal.eta) revert AegisVaults__TimelockNotPassed();

        proposal.executed = true;
        (bool success, ) = proposal.target.call{value: proposal.value}(proposal.callData);
        if (!success) revert AegisVaults__CallFailed();

        emit ProposalExecuted(_proposalId);
    }

    /**
     * @notice Cancels a proposal.
     * @dev Can be called by the `proposer` (if not yet active/queued) or by the `owner` (acting as DAO executive).
     *      A new DAO governance proposal can also be used to cancel an active or queued proposal by calling this function via `executeProposal`.
     * @param _proposalId The ID of the proposal to cancel.
     */
    function cancelProposal(uint256 _proposalId) public {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.canceled) revert AegisVaults__ProposalAlreadyCanceled();
        if (proposal.executed) revert AegisVaults__ProposalAlreadyExecuted();

        // Allow proposer to cancel if it's still pending (not active/queued)
        if (msg.sender == proposal.proposer && getProposalState(_proposalId) == ProposalState.Pending) {
            proposal.canceled = true;
            emit ProposalCanceled(_proposalId);
            return;
        }

        // Otherwise, only the owner (representing executed DAO vote) can cancel
        if (msg.sender != owner()) revert AegisVaults__Unauthorized();

        proposal.canceled = true;
        emit ProposalCanceled(_proposalId);
    }

    /**
     * @notice Allows external parties to deposit ERC20 tokens into the DAO's main treasury.
     * @dev Any ERC20 token can be deposited. This increases the collective investment capital.
     * @param _token Address of the ERC20 token to deposit.
     * @param _amount Amount of tokens to deposit.
     */
    function depositTreasury(address _token, uint256 _amount) public {
        if (_token == address(0)) revert AegisVaults__ZeroAddress();
        if (_amount == 0) revert AegisVaults__InvalidAmount();

        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        treasuryBalances[_token] = treasuryBalances[_token].add(_amount);
        emit TreasuryDeposit(_token, _amount, msg.sender);
    }

    /**
     * @notice Allows the DAO (via governance proposal) to withdraw funds from its treasury.
     * @dev This function would typically be called via `executeProposal` by the DAO itself, e.g., to fund a strategy or pay expenses.
     *      The `owner` role here signifies that it's an action approved by governance.
     * @param _token Address of the ERC20 token to withdraw.
     * @param _amount Amount of tokens to withdraw.
     */
    function withdrawTreasury(address _token, uint256 _amount) public onlyOwner {
        if (_token == address(0)) revert AegisVaults__ZeroAddress();
        if (_amount == 0) revert AegisVaults__InvalidAmount();
        if (treasuryBalances[_token] < _amount) revert AegisVaults__InsufficientTreasuryBalance();

        treasuryBalances[_token] = treasuryBalances[_token].sub(_amount);
        // In a real DAO, `owner()` would typically be replaced by the `_target` of the governance proposal,
        // allowing flexible recipient definition. For simplicity, it withdraws to the current owner.
        IERC20(_token).transfer(owner(), _amount);
        emit TreasuryWithdrawal(_token, _amount, owner());
    }

    /**
     * @notice Allows the DAO to update its own governance parameters.
     * @dev This function would typically be called via `executeProposal` by the DAO itself.
     *      This demonstrates the DAO's ability to self-amend its rules.
     * @param _newVotingDelay New voting delay in blocks.
     * @param _newVotingPeriod New voting period in blocks.
     * @param _newQuorumNumerator New quorum numerator (e.g., 4000 for 40% quorum).
     */
    function updateGovernanceParameters(
        uint256 _newVotingDelay,
        uint256 _newVotingPeriod,
        uint256 _newQuorumNumerator
    ) public onlyOwner {
        votingDelayBlocks = _newVotingDelay;
        votingPeriodBlocks = _newVotingPeriod;
        quorumNumerator = _newQuorumNumerator;
        emit GovernanceParametersUpdated(_newVotingDelay, _newVotingPeriod, _newQuorumNumerator);
    }

    // --- II. Strategy Management & Lifecycle ---

    /**
     * @notice Registers a new strategy contract, making it eligible for funding by the DAO.
     * @dev This function would typically be called via `executeProposal` by the DAO itself.
     *      Performs basic checks to ensure the address is a contract and implements the `IStrategy` interface.
     * @param _strategyAddress The address of the strategy contract (must implement `IStrategy`).
     * @param _name A human-readable name for the strategy.
     * @param _description A detailed description of the strategy's purpose.
     * @param _isPublic Whether the strategy's performance and trades are publicly visible for user subscription.
     */
    function registerStrategy(
        address _strategyAddress,
        string memory _name,
        string memory _description,
        bool _isPublic
    ) public onlyOwner {
        if (_strategyAddress == address(0)) revert AegisVaults__ZeroAddress();
        if (strategies[_strategyAddress].strategyAddress != address(0)) revert AegisVaults__StrategyAlreadyRegistered();

        if (!_strategyAddress.isContract()) revert AegisVaults__NotAContract();

        // Attempt to call a view function to check basic IStrategy interface conformance
        // This is a minimal check; a more robust check would involve EIP-165.
        address strategist;
        try IStrategy(_strategyAddress).getStrategistAddress() returns (address s) {
            strategist = s;
        } catch {
            revert AegisVaults__InvalidStrategyInterface();
        }
        if (strategist == address(0)) revert AegisVaults__InvalidStrategyInterface();

        strategies[_strategyAddress] = StrategyInfo({
            strategyAddress: _strategyAddress,
            name: _name,
            description: _description,
            strategist: strategist,
            status: StrategyStatus.PendingReview, // Starts as pending, DAO needs to activate it
            isPublic: _isPublic,
            registeredTimestamp: block.timestamp,
            maxDrawdownBps: 0, // Default to 0, DAO sets later via setStrategyGuardrails
            maxAllocationBps: 0, // Default to 0, DAO sets later via setStrategyGuardrails
            configuredHooks: new mapping(bytes4 => address) // Initialize mapping
        });
        registeredStrategyAddresses.push(_strategyAddress);
        emit StrategyRegistered(_strategyAddress, _name, strategist, _isPublic);
    }

    /**
     * @notice Deregisters a strategy, preventing further fund allocation and marking it for deprecation.
     * @dev This function would typically be called via `executeProposal` by the DAO itself.
     *      Funds held by the strategy should be deallocated via `deallocateFromStrategy` first.
     * @param _strategyAddress The address of the strategy to deregister.
     */
    function deregisterStrategy(address _strategyAddress) public onlyOwner {
        if (strategies[_strategyAddress].strategyAddress == address(0)) revert AegisVaults__StrategyNotRegistered();

        // Mark as deprecated. Funds must be deallocated separately.
        strategies[_strategyAddress].status = StrategyStatus.Deprecated;
        emit StrategyDeregistered(_strategyAddress);
    }

    /**
     * @notice Allocates specific tokens from the DAO treasury to a registered strategy.
     * @dev This function would typically be called via `executeProposal` by the DAO itself.
     *      The target strategy must be `Active`.
     * @param _strategyAddress The address of the target strategy.
     * @param _token The address of the token to allocate.
     * @param _amount The amount of tokens to allocate.
     */
    function allocateToStrategy(address _strategyAddress, address _token, uint256 _amount) public onlyOwner {
        StrategyInfo storage strat = strategies[_strategyAddress];
        if (strat.strategyAddress == address(0) || strat.status != StrategyStatus.Active) revert AegisVaults__StrategyNotActive();
        if (_token == address(0)) revert AegisVaults__ZeroAddress();
        if (_amount == 0) revert AegisVaults__InvalidAmount();
        if (treasuryBalances[_token] < _amount) revert AegisVaults__InsufficientTreasuryBalance();

        treasuryBalances[_token] = treasuryBalances[_token].sub(_amount);
        require(IStrategy(_strategyAddress).receiveFunds(_token, _amount), "AegisVaults: Strategy failed to receive funds.");

        emit FundsAllocatedToStrategy(_strategyAddress, _token, _amount);
    }

    /**
     * @notice Recalls specific tokens from a strategy back to the DAO treasury.
     * @dev This function would typically be called via `executeProposal` by the DAO itself.
     *      The strategy must return the funds via its `returnFunds` function.
     * @param _strategyAddress The address of the strategy to recall from.
     * @param _token The address of the token to recall.
     * @param _amount The amount of tokens to recall.
     */
    function deallocateFromStrategy(address _strategyAddress, address _token, uint256 _amount) public onlyOwner {
        StrategyInfo storage strat = strategies[_strategyAddress];
        if (strat.strategyAddress == address(0)) revert AegisVaults__StrategyNotRegistered();
        if (_token == address(0)) revert AegisVaults__ZeroAddress();
        if (_amount == 0) revert AegisVaults__InvalidAmount();

        // The strategy itself must handle returning funds
        require(IStrategy(_strategyAddress).returnFunds(_token, _amount), "AegisVaults: Strategy failed to return funds.");
        treasuryBalances[_token] = treasuryBalances[_token].add(_amount); // Update treasury balance after successful return

        emit FundsDeallocatedFromStrategy(_strategyAddress, _token, _amount);
    }

    /**
     * @notice Changes the operational status of a registered strategy.
     * @dev This function would typically be called via `executeProposal` by the DAO itself.
     *      Can trigger `pause()` or `unpause()` calls on the strategy contract.
     * @param _strategyAddress The address of the strategy.
     * @param _newStatus The new status to set (e.g., Active, Paused, Malicious).
     */
    function updateStrategyStatus(address _strategyAddress, StrategyStatus _newStatus) public onlyOwner {
        StrategyInfo storage strat = strategies[_strategyAddress];
        if (strat.strategyAddress == address(0)) revert AegisVaults__StrategyNotRegistered();

        strat.status = _newStatus;
        if (_newStatus == StrategyStatus.Paused) {
            IStrategy(_strategyAddress).pause();
        } else if (_newStatus == StrategyStatus.Active) {
            IStrategy(_strategyAddress).unpause();
        }
        // For Malicious or Deprecated, no direct call is made as strategy might not be responsive.

        emit StrategyStatusUpdated(_strategyAddress, _newStatus);
    }

    /**
     * @notice Sets risk parameters for a strategy, such as maximum drawdown and allocation limits.
     * @dev This function would typically be called via `executeProposal` by the DAO itself.
     *      These guardrails guide DAO decisions on fund allocation and serve as alerts for off-chain monitoring.
     * @param _strategyAddress The address of the strategy.
     * @param _maxDrawdownBps Maximum allowed drawdown from peak equity in basis points (e.g., 5000 for 50%).
     * @param _maxAllocationBps Maximum percentage of total treasury allocable to this strategy in basis points.
     */
    function setStrategyGuardrails(address _strategyAddress, uint256 _maxDrawdownBps, uint256 _maxAllocationBps) public onlyOwner {
        StrategyInfo storage strat = strategies[_strategyAddress];
        if (strat.strategyAddress == address(0)) revert AegisVaults__StrategyNotRegistered();

        strat.maxDrawdownBps = _maxDrawdownBps;
        strat.maxAllocationBps = _maxAllocationBps;
        emit StrategyGuardrailsUpdated(_strategyAddress, _maxDrawdownBps, _maxAllocationBps);
    }

    /**
     * @notice Allows immediate pausing of a strategy in critical situations, bypassing standard status updates if needed.
     * @dev This function would typically be called via `executeProposal` by the DAO itself (or a designated emergency multisig).
     *      It ensures rapid response to potential exploits or critical malfunctions.
     * @param _strategyAddress The address of the strategy to pause.
     */
    function emergencyPauseStrategy(address _strategyAddress) public onlyOwner {
        StrategyInfo storage strat = strategies[_strategyAddress];
        if (strat.strategyAddress == address(0)) revert AegisVaults__StrategyNotRegistered();
        if (strat.status == StrategyStatus.Paused) return; // Already paused

        strat.status = StrategyStatus.Paused; // Set status to Paused
        IStrategy(_strategyAddress).pause(); // Attempt to call pause on the strategy contract
        emit StrategyEmergencyPaused(_strategyAddress);
    }

    // --- III. Performance, Fees & Reputation ---

    /**
     * @notice Retrieves calculated on-chain performance metrics and the strategist's reputation score.
     * @param _strategyAddress The address of the strategy.
     * @return currentTVL Total Value Locked within the strategy, as reported by the strategy itself.
     * @return netProfitBps Net profit/loss in basis points, as reported by the strategy.
     * @return strategistRepScore The reputation score of the strategist maintained by AegisVaults.
     */
    function getStrategyPerformanceMetrics(address _strategyAddress)
        public
        view
        returns (uint256 currentTVL, int256 netProfitBps, uint256 strategistRepScore)
    {
        StrategyInfo storage strat = strategies[_strategyAddress];
        if (strat.strategyAddress == address(0)) revert AegisVaults__StrategyNotRegistered();

        currentTVL = IStrategy(_strategyAddress).getCurrentTVL();
        netProfitBps = IStrategy(_strategyAddress).getNetProfit();
        strategistRepScore = strategistReputation[strat.strategist];
    }

    /**
     * @notice Allows the DAO to distribute a specified amount of a token from its treasury to a strategist as fees.
     * @dev This function would typically be called via `executeProposal` by the DAO itself, after governance has decided on an amount.
     *      The `_amount` is explicitly passed as part of the `_callData` during the `propose` stage.
     * @param _strategist The address of the strategist to pay.
     * @param _token The address of the ERC20 token to distribute.
     * @param _amount The exact amount of tokens to distribute.
     */
    function distributeStrategistFees(address _strategist, address _token, uint256 _amount) public onlyOwner {
        if (_strategist == address(0) || _token == address(0)) revert AegisVaults__ZeroAddress();
        if (_amount == 0) revert AegisVaults__InvalidAmount();
        if (treasuryBalances[_token] < _amount) revert AegisVaults__InsufficientTreasuryBalance();

        treasuryBalances[_token] = treasuryBalances[_token].sub(_amount);
        IERC20(_token).transfer(_strategist, _amount);
        emit StrategistFeesDistributed(_strategist, _token, _amount);
    }

    /**
     * @notice Allows the DAO to adjust a strategist's reputation score.
     * @dev This function would typically be called via `executeProposal` by the DAO itself,
     *      based on off-chain audits, community feedback, prolonged performance, or other subjective criteria.
     * @param _strategist The address of the strategist whose reputation to update.
     * @param _newReputationScore The new reputation score to set for the strategist.
     */
    function updateStrategistReputation(address _strategist, uint256 _newReputationScore) public onlyOwner {
        if (_strategist == address(0)) revert AegisVaults__ZeroAddress();
        strategistReputation[_strategist] = _newReputationScore;
        emit StrategistReputationUpdated(_strategist, _newReputationScore);
    }

    /**
     * @notice Allows a user to "subscribe" to a public strategy.
     * @dev This is currently a signaling mechanism for user interest. In future iterations, it could enable
     *      off-chain copy-trading notifications, access to exclusive strategy insights, or other community features.
     * @param _strategyAddress The address of the strategy to subscribe to.
     */
    function subscribeToStrategy(address _strategyAddress) public {
        StrategyInfo storage strat = strategies[_strategyAddress];
        if (strat.strategyAddress == address(0) || !strat.isPublic) revert AegisVaults__StrategyNotRegistered();
        require(!userSubscriptions[msg.sender][_strategyAddress], "AegisVaults: Already subscribed.");

        userSubscriptions[msg.sender][_strategyAddress] = true;
        emit StrategySubscribed(msg.sender, _strategyAddress);
    }

    /**
     * @notice Allows a user to revoke their strategy subscription.
     * @param _strategyAddress The address of the strategy to unsubscribe from.
     */
    function unsubscribeFromStrategy(address _strategyAddress) public {
        StrategyInfo storage strat = strategies[_strategyAddress];
        if (strat.strategyAddress == address(0)) revert AegisVaults__StrategyNotRegistered();
        require(userSubscriptions[msg.sender][_strategyAddress], "AegisVaults: Not subscribed.");

        userSubscriptions[msg.sender][_strategyAddress] = false;
        emit StrategyUnsubscribed(msg.sender, _strategyAddress);
    }

    // --- IV. Advanced & Extensible Features ---

    /**
     * @notice Allows the DAO to configure specific "hooks" for a strategy.
     * @dev Hooks enable strategies to securely interact with approved external contracts (e.g., DEX aggregators,
     *      lending protocols, custom yield optimizers) without needing a full strategy redeploy.
     *      This function would typically be called via `executeProposal` by the DAO itself.
     *      The strategy contract must implement `supportsHook` and `callHook` for this to be effective.
     * @param _strategyAddress The address of the strategy to configure.
     * @param _hookSignature The bytes4 signature of the hook function that the strategy will call.
     * @param _hookTarget The address of the external contract that implements the hook's functionality.
     */
    function configureStrategyHook(
        address _strategyAddress,
        bytes4 _hookSignature,
        address _hookTarget
    ) public onlyOwner {
        StrategyInfo storage strat = strategies[_strategyAddress];
        if (strat.strategyAddress == address(0)) revert AegisVaults__StrategyNotRegistered();
        if (_hookTarget == address(0)) revert AegisVaults__ZeroAddress();

        // Verify the strategy explicitly supports this hook type (via EIP-165 or custom `supportsHook`)
        require(IStrategy(_strategyAddress).supportsHook(_hookSignature), "AegisVaults: Strategy does not support this hook.");

        strat.configuredHooks[_hookSignature] = _hookTarget;
        emit StrategyHookConfigured(_strategyAddress, _hookSignature, _hookTarget);
    }

    /**
     * @notice Retrieves the current balance of a specific ERC20 token held in the main DAO treasury.
     * @param _token The address of the ERC20 token to query.
     * @return The balance of the token held by the AegisVaults contract.
     */
    function getTreasuryBalance(address _token) public view returns (uint256) {
        return treasuryBalances[_token];
    }

    /**
     * @notice Retrieves all publicly available registered information about a specific strategy.
     * @param _strategyAddress The address of the strategy to query.
     * @return A `StrategyInfo` struct containing detailed information about the strategy.
     */
    function getStrategyInfo(address _strategyAddress) public view returns (StrategyInfo memory) {
        if (strategies[_strategyAddress].strategyAddress == address(0)) revert AegisVaults__StrategyNotRegistered();
        return strategies[_strategyAddress];
    }

    // --- View Functions (Helpers) ---

    /**
     * @notice Gets the current state of a governance proposal.
     * @param _proposalId The ID of the proposal to query.
     * @return The current `ProposalState` of the proposal.
     */
    function getProposalState(uint256 _proposalId) public view returns (ProposalState) {
        Proposal storage proposal = proposals[_proposalId];

        if (proposal.canceled) {
            return ProposalState.Canceled;
        } else if (proposal.executed) {
            return ProposalState.Executed;
        } else if (proposal.eta != 0) { // If ETA is set, it's queued or executable
            if (block.timestamp >= proposal.eta) {
                return ProposalState.Queued; // Ready for execution after timelock (or already ready)
            } else {
                return ProposalState.Queued; // In timelock period
            }
        } else if (block.number < proposal.voteStartBlock) {
            return ProposalState.Pending;
        } else if (block.number <= proposal.voteEndBlock) {
            return ProposalState.Active;
        } else {
            // Voting period has ended, determine if succeeded or defeated
            uint256 totalVotes = proposal.forVotes.add(proposal.againstVotes).add(proposal.abstainVotes);
            // Calculate quorum based on the total voting power of the governance token
            uint256 totalVotingPower = IGovernanceToken(governanceToken).getVotes(address(this)); // Using address(this) to represent the entire protocol's voting power or delegated power
            uint256 quorumRequired = totalVotingPower.mul(quorumNumerator).div(QUORUM_DENOMINATOR);

            if (totalVotes < quorumRequired) {
                return ProposalState.Defeated; // Quorum not met
            } else if (proposal.forVotes <= proposal.againstVotes) {
                return ProposalState.Defeated; // 'For' votes did not exceed 'against' votes
            } else {
                return ProposalState.Succeeded; // Quorum met and 'for' votes exceeded 'against' votes
            }
        }
    }

    /**
     * @notice Returns an array of all addresses of strategies currently registered with the protocol.
     * @return An array of `address` representing all registered strategy contracts.
     */
    function getAllRegisteredStrategies() public view returns (address[] memory) {
        return registeredStrategyAddresses;
    }

    /**
     * @notice Returns the total number of proposals that have been created in the protocol.
     * @return The total count of proposals.
     */
    function getTotalProposals() public view returns (uint256) {
        return nextProposalId - 1;
    }
}
```