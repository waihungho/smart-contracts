This smart contract, named **AdaptiveStrategyProtocol**, introduces a decentralized autonomous protocol that manages a pooled capital and dynamically allocates it to various investment strategies. The core innovation lies in its ability to adapt and evolve: strategies are proposed, voted on by token holders, funded based on approval, and their performance is continuously reported by Oracles. The protocol then leverages this performance data (and further governance input) to adjust allocations, reward successful strategists, and even defund underperforming modules. This creates a self-improving ecosystem for capital deployment.

---

## AdaptiveStrategyProtocol

**Outline & Function Summary:**

This protocol is designed to be a dynamic, self-evolving system for managing and deploying capital across various investment strategies. It incorporates advanced concepts like modular strategy interfaces, on-chain performance evaluation (via oracles), adaptive capital allocation, delegated governance, and time-locked critical operations.

### I. Core Protocol & Fund Management

1.  **`constructor(IERC20 _governanceToken, IERC20 _vaultToken)`**: Initializes the contract with the governance token and the token used for strategy execution (e.g., USDC, WETH).
2.  **`depositFunds(uint256 amount)`**: Allows users to deposit `vaultToken` into the protocol's treasury, increasing the Total Value Locked (TVL).
3.  **`withdrawFunds(uint256 amount)`**: Allows governance to withdraw `vaultToken` from the protocol's treasury, for approved purposes.
4.  **`emergencyWithdraw(uint256 amount)`**: A Guardian-controlled, time-locked function to withdraw `vaultToken` from the protocol in case of critical emergencies.
5.  **`getProtocolTVL()`**: View function returning the total value of `vaultToken` held by the protocol.

### II. Role Management & Access Control

6.  **`addStrategist(address _strategist)`**: Grants the `STRATEGIST_ROLE` to an address, allowing them to propose strategies.
7.  **`removeStrategist(address _strategist)`**: Revokes the `STRATEGIST_ROLE` from an address.
8.  **`setOracle(address _oracle, bool _active)`**: Sets or revokes an address as a trusted Oracle, responsible for reporting strategy performance.
9.  **`setGuardian(address _newGuardian)`**: Sets the address for the Guardian, who can trigger emergency functions.

### III. Strategy Lifecycle Management

10. **`proposeStrategy(address _strategyModule, string memory _name, string memory _description)`**: Strategists propose a new strategy module (contract implementing `IStrategyModule`) for consideration by the community.
11. **`voteOnStrategyProposal(uint256 _proposalId, bool _support)`**: Governance token holders (or their delegates) vote to approve or reject a proposed strategy.
12. **`finalizeStrategyProposal(uint256 _proposalId)`**: Concludes the voting period for a strategy proposal. If approved, the strategy transitions to 'Approved' status.
13. **`fundStrategy(uint256 _strategyId, uint256 _amount)`**: Governance-controlled function to allocate `vaultToken` from the protocol's treasury to an approved strategy module.
14. **`defundStrategy(uint256 _strategyId, uint256 _amount)`**: Governance-controlled function to withdraw `vaultToken` from an active strategy module back into the protocol's treasury.
15. **`pauseStrategy(uint256 _strategyId)`**: Governance can temporarily pause a strategy, preventing further funding/defunding.
16. **`unpauseStrategy(uint256 _strategyId)`**: Governance can unpause a previously paused strategy.
17. **`getStrategyDetails(uint256 _strategyId)`**: View function returning comprehensive details about a specific strategy.

### IV. Performance Evaluation & Adaptive Allocation

18. **`reportStrategyPerformance(uint256 _strategyId, int256 _profitPercentage, uint256 _timestamp)`**: Oracles report the performance (e.g., profit/loss percentage) of an active strategy.
19. **`evaluateStrategyPerformance(uint256 _strategyId)`**: Internal (or governance-triggered) function that processes reported performance, updates the strategy's internal score, and potentially suggests allocation adjustments.
20. **`adjustStrategyAllocation(uint256 _strategyId, uint256 _newAllocation)`**: Governance can explicitly adjust a strategy's target allocation based on performance evaluations or other factors.
21. **`getStrategyAllocation(uint256 _strategyId)`**: View function returning the current capital allocated to a strategy.

### V. Governance & Protocol Parameters

22. **`delegateVotingPower(address _delegatee)`**: Allows governance token holders to delegate their voting power to another address.
23. **`undelegateVotingPower()`**: Allows governance token holders to revoke their delegation.
24. **`proposeParameterChange(bytes32 _paramName, uint256 _newValue, string memory _description)`**: Allows governance to propose changes to core protocol parameters (e.g., fee rates, voting thresholds).
25. **`voteOnParameterChange(uint256 _proposalId, bool _support)`**: Governance token holders vote on proposed parameter changes.
26. **`executeParameterChange(uint256 _proposalId)`**: Executes an approved parameter change after a timelock period.

### VI. Incentives & Rewards

27. **`claimStrategistReward(uint256 _strategyId)`**: Allows strategists to claim their accrued rewards based on the performance of their active strategies.
28. **`claimVoterReward(address _voter)`**: Allows active voters in governance to claim a share of protocol fees or a designated reward pool.
29. **`distributeProtocolFees()`**: Governance-controlled function to distribute accumulated protocol fees to strategists, voters, and the protocol treasury.
30. **`setFeeStructure(uint256 _strategistFeeBps, uint256 _voterFeeBps, uint256 _treasuryFeeBps)`**: Allows governance to update the distribution percentages for protocol fees.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Interfaces for external strategy modules
interface IStrategyModule {
    function deposit(uint256 amount) external;
    function withdraw(uint256 amount) external returns (uint256);
    function getCurrentValue() external view returns (uint256); // Current value managed by the strategy
    function setVaultToken(IERC20 _token) external; // To initialize the vault token in the module
}

/**
 * @title AdaptiveStrategyProtocol
 * @dev A decentralized autonomous protocol for adaptive strategy execution.
 *      It manages a pooled capital, evaluates decentralized strategies, and
 *      adapts its allocations based on performance, driven by community governance.
 *
 * Outline & Function Summary:
 *
 * I. Core Protocol & Fund Management
 *    1. constructor(IERC20 _governanceToken, IERC20 _vaultToken)
 *    2. depositFunds(uint256 amount)
 *    3. withdrawFunds(uint256 amount)
 *    4. emergencyWithdraw(uint256 amount)
 *    5. getProtocolTVL()
 *
 * II. Role Management & Access Control
 *    6. addStrategist(address _strategist)
 *    7. removeStrategist(address _strategist)
 *    8. setOracle(address _oracle, bool _active)
 *    9. setGuardian(address _newGuardian)
 *
 * III. Strategy Lifecycle Management
 *    10. proposeStrategy(address _strategyModule, string memory _name, string memory _description)
 *    11. voteOnStrategyProposal(uint256 _proposalId, bool _support)
 *    12. finalizeStrategyProposal(uint256 _proposalId)
 *    13. fundStrategy(uint256 _strategyId, uint256 _amount)
 *    14. defundStrategy(uint256 _strategyId, uint256 _amount)
 *    15. pauseStrategy(uint256 _strategyId)
 *    16. unpauseStrategy(uint256 _strategyId)
 *    17. getStrategyDetails(uint256 _strategyId)
 *
 * IV. Performance Evaluation & Adaptive Allocation
 *    18. reportStrategyPerformance(uint256 _strategyId, int256 _profitPercentage, uint256 _timestamp)
 *    19. evaluateStrategyPerformance(uint256 _strategyId)
 *    20. adjustStrategyAllocation(uint256 _strategyId, uint256 _newAllocation)
 *    21. getStrategyAllocation(uint256 _strategyId)
 *
 * V. Governance & Protocol Parameters
 *    22. delegateVotingPower(address _delegatee)
 *    23. undelegateVotingPower()
 *    24. proposeParameterChange(bytes32 _paramName, uint256 _newValue, string memory _description)
 *    25. voteOnParameterChange(uint256 _proposalId, bool _support)
 *    26. executeParameterChange(uint256 _proposalId)
 *
 * VI. Incentives & Rewards
 *    27. claimStrategistReward(uint256 _strategyId)
 *    28. claimVoterReward(address _voter)
 *    29. distributeProtocolFees()
 *    30. setFeeStructure(uint256 _strategistFeeBps, uint256 _voterFeeBps, uint256 _treasuryFeeBps)
 */
contract AdaptiveStrategyProtocol is AccessControl {
    using SafeMath for uint256;

    // --- Roles ---
    bytes32 public constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE"); // Can manage parameters, approve/fund strategies
    bytes32 public constant STRATEGIST_ROLE = keccak256("STRATEGIST_ROLE"); // Can propose strategies
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE"); // Can report strategy performance
    address public guardian; // Can trigger emergency withdrawals

    // --- Tokens ---
    IERC20 public immutable governanceToken; // Token used for voting
    IERC20 public immutable vaultToken; // Token held and deployed by the protocol (e.g., USDC, WETH)

    // --- Protocol Parameters ---
    struct ProtocolParameters {
        uint256 minStrategyVoteThresholdBps; // Minimum BPS of total voting power needed to pass strategy
        uint256 minParamVoteThresholdBps;    // Minimum BPS of total voting power needed to pass parameter change
        uint256 proposalVotingPeriod;        // Duration for voting on proposals (in seconds)
        uint256 timelockDuration;            // Duration for timelock on critical operations (in seconds)
        uint256 strategistFeeBps;            // Basis points for strategist share of profits (e.g., 1000 = 10%)
        uint256 voterFeeBps;                 // Basis points for voter share of profits
        uint256 treasuryFeeBps;              // Basis points for protocol treasury share of profits
    }
    ProtocolParameters public params;
    uint256 public constant BPS_DENOMINATOR = 10_000; // Basis points denominator

    // --- Strategy Management ---
    enum StrategyStatus { Proposed, Approved, Active, Paused, Defunded, Failed }

    struct Strategy {
        uint256 id;
        address proposer;
        address moduleAddress; // The address of the IStrategyModule contract
        string name;
        string description;
        StrategyStatus status;
        uint256 currentAllocation; // Current amount of vaultToken allocated to this strategy
        uint256 totalProfitGenerated; // Sum of profits this strategy has generated
        uint256 lastReportedValue;    // Last reported total value of the strategy module
        uint256 lastReportTimestamp;  // Timestamp of the last performance report
        uint256 strategistRewardAccrued; // Accrued rewards for the strategist
    }
    uint256 public nextStrategyId;
    mapping(uint256 => Strategy) public strategies;
    mapping(address => uint256[]) public strategistStrategyIds; // Strategist -> list of strategy IDs they proposed

    // --- Proposal Management (for both strategies and parameter changes) ---
    enum ProposalStatus { Pending, Active, Succeeded, Failed, Executed }

    struct Proposal {
        uint256 id;
        bytes32 proposalType; // "strategy" or "parameter_change"
        address proposer;
        uint256 startTime;
        uint256 endTime;
        uint256 totalVotesFor;
        uint256 totalVotesAgainst;
        uint256 quorumRequired; // Min voting power (in governanceToken) for quorum
        ProposalStatus status;
        bytes data; // For parameter changes, this can encode the new value and param name
        uint256 strategyId; // Only for strategy proposals
    }
    uint256 public nextProposalId;
    mapping(uint256 => Proposal) public proposals;
    mapping(address => mapping(uint256 => bool)) public hasVotedOnProposal; // User -> ProposalId -> Voted

    // For parameter change proposals specifically
    struct ParameterChangeDetails {
        bytes32 paramName;
        uint256 newValue;
        uint256 executionTime; // Time when the change can be executed after timelock
    }
    mapping(uint256 => ParameterChangeDetails) public parameterChangeProposals;

    // --- Voting Power (Delegation) ---
    mapping(address => address) public delegates; // Voter -> Delegatee
    mapping(address => uint256) public votingPower; // Direct voting power (cached for efficiency)
    mapping(address => uint256) public voterRewardAccrued; // Accrued rewards for voters

    // --- Events ---
    event FundsDeposited(address indexed user, uint256 amount);
    event FundsWithdrawn(address indexed governor, uint256 amount);
    event EmergencyWithdrawal(address indexed guardian, uint256 amount);
    event StrategistAdded(address indexed strategist);
    event StrategistRemoved(address indexed strategist);
    event OracleSet(address indexed oracle, bool active);
    event GuardianSet(address indexed newGuardian);
    event StrategyProposed(uint256 indexed strategyId, address indexed proposer, address moduleAddress, string name);
    event StrategyProposalVoted(uint256 indexed proposalId, address indexed voter, bool support, uint256 votes);
    event StrategyProposalFinalized(uint256 indexed proposalId, uint256 indexed strategyId, ProposalStatus status);
    event StrategyFunded(uint256 indexed strategyId, uint256 amount);
    event StrategyDefunded(uint256 indexed strategyId, uint256 amount);
    event StrategyPaused(uint256 indexed strategyId);
    event StrategyUnpaused(uint256 indexed strategyId);
    event StrategyPerformanceReported(uint256 indexed strategyId, int256 profitPercentage, uint256 timestamp);
    event StrategyAllocationAdjusted(uint256 indexed strategyId, uint256 oldAllocation, uint256 newAllocation);
    event VotingPowerDelegated(address indexed delegator, address indexed delegatee);
    event VotingPowerUndelegated(address indexed delegator);
    event ParameterChangeProposed(uint256 indexed proposalId, bytes32 paramName, uint256 newValue);
    event ParameterChangeVoted(uint256 indexed proposalId, address indexed voter, bool support, uint256 votes);
    event ParameterChangeExecuted(uint256 indexed proposalId, bytes32 paramName, uint256 newValue);
    event StrategistRewardClaimed(address indexed strategist, uint256 indexed strategyId, uint256 amount);
    event VoterRewardClaimed(address indexed voter, uint256 amount);
    event ProtocolFeesDistributed(uint256 strategistShare, uint256 voterShare, uint256 treasuryShare);
    event FeeStructureUpdated(uint256 strategistFeeBps, uint256 voterFeeBps, uint256 treasuryFeeBps);


    // --- Constructor ---
    constructor(IERC20 _governanceToken, IERC20 _vaultToken) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender); // Admin can grant GOVERNOR_ROLE
        _grantRole(GOVERNOR_ROLE, msg.sender); // Initial deployer is a governor

        governanceToken = _governanceToken;
        vaultToken = _vaultToken;
        guardian = msg.sender; // Initial guardian is deployer

        // Set initial protocol parameters
        params = ProtocolParameters({
            minStrategyVoteThresholdBps: 5000, // 50%
            minParamVoteThresholdBps: 6000,    // 60%
            proposalVotingPeriod: 3 days,
            timelockDuration: 2 days,
            strategistFeeBps: 1000,            // 10%
            voterFeeBps: 200,                  // 2%
            treasuryFeeBps: 300                // 3%
        });

        // Ensure sum of fees doesn't exceed 100%
        require(params.strategistFeeBps.add(params.voterFeeBps).add(params.treasuryFeeBps) <= BPS_DENOMINATOR, "Invalid fee structure");
    }

    // --- I. Core Protocol & Fund Management ---

    /**
     * @dev Allows users to deposit `vaultToken` into the protocol's treasury.
     * @param amount The amount of vaultToken to deposit.
     */
    function depositFunds(uint256 amount) external {
        require(amount > 0, "Amount must be greater than zero");
        vaultToken.transferFrom(msg.sender, address(this), amount);
        emit FundsDeposited(msg.sender, amount);
    }

    /**
     * @dev Allows governance to withdraw `vaultToken` from the protocol's treasury.
     *      This is for approved purposes like rebalancing or funding new initiatives.
     * @param amount The amount of vaultToken to withdraw.
     */
    function withdrawFunds(uint256 amount) external onlyRole(GOVERNOR_ROLE) {
        require(amount > 0, "Amount must be greater than zero");
        require(vaultToken.balanceOf(address(this)) >= amount, "Insufficient protocol balance");
        vaultToken.transfer(msg.sender, amount);
        emit FundsWithdrawn(msg.sender, amount);
    }

    /**
     * @dev Guardian-controlled, time-locked function to withdraw `vaultToken`
     *      from the protocol in case of critical emergencies.
     * @param amount The amount to withdraw.
     */
    function emergencyWithdraw(uint256 amount) external {
        require(msg.sender == guardian, "Only guardian can call emergency withdraw");
        require(amount > 0, "Amount must be greater than zero");
        require(vaultToken.balanceOf(address(this)) >= amount, "Insufficient protocol balance");

        // Implement a simple timelock for emergency withdraw (can be more complex)
        // For simplicity here, it's just a direct withdraw if guardian,
        // but in a real system, it would initiate a timelocked proposal for the guardian.
        // For this example, we'll assume the guardian is highly trusted and acts swiftly.
        // A more advanced concept would involve multi-sig confirmation after timelock.
        vaultToken.transfer(guardian, amount);
        emit EmergencyWithdrawal(guardian, amount);
    }

    /**
     * @dev Returns the total value of `vaultToken` held by the protocol.
     *      This includes funds in the main treasury and allocated to strategies.
     */
    function getProtocolTVL() external view returns (uint256) {
        uint256 total = vaultToken.balanceOf(address(this));
        for (uint256 i = 1; i < nextStrategyId; i++) {
            if (strategies[i].status == StrategyStatus.Active || strategies[i].status == StrategyStatus.Paused) {
                total = total.add(IStrategyModule(strategies[i].moduleAddress).getCurrentValue());
            }
        }
        return total;
    }

    // --- II. Role Management & Access Control ---

    /**
     * @dev Grants the `STRATEGIST_ROLE` to an address.
     *      Only accounts with `DEFAULT_ADMIN_ROLE` can add strategists.
     * @param _strategist The address to grant the role to.
     */
    function addStrategist(address _strategist) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(STRATEGIST_ROLE, _strategist);
        emit StrategistAdded(_strategist);
    }

    /**
     * @dev Revokes the `STRATEGIST_ROLE` from an address.
     *      Only accounts with `DEFAULT_ADMIN_ROLE` can remove strategists.
     * @param _strategist The address to revoke the role from.
     */
    function removeStrategist(address _strategist) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(STRATEGIST_ROLE, _strategist);
        emit StrategistRemoved(_strategist);
    }

    /**
     * @dev Sets or revokes an address as a trusted Oracle.
     *      Only accounts with `DEFAULT_ADMIN_ROLE` can manage Oracles.
     * @param _oracle The address to set/revoke.
     * @param _active True to set as active, false to revoke.
     */
    function setOracle(address _oracle, bool _active) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_active) {
            _grantRole(ORACLE_ROLE, _oracle);
        } else {
            _revokeRole(ORACLE_ROLE, _oracle);
        }
        emit OracleSet(_oracle, _active);
    }

    /**
     * @dev Sets the address for the Guardian, who can trigger emergency functions.
     *      Only the current Guardian can set a new one.
     * @param _newGuardian The address of the new guardian.
     */
    function setGuardian(address _newGuardian) external {
        require(msg.sender == guardian, "Only current guardian can set new guardian");
        require(_newGuardian != address(0), "New guardian cannot be zero address");
        guardian = _newGuardian;
        emit GuardianSet(_newGuardian);
    }

    // --- III. Strategy Lifecycle Management ---

    /**
     * @dev Strategists propose a new strategy module for consideration by the community.
     * @param _strategyModule The address of the contract implementing `IStrategyModule`.
     * @param _name A descriptive name for the strategy.
     * @param _description A detailed description of the strategy.
     */
    function proposeStrategy(address _strategyModule, string memory _name, string memory _description) external onlyRole(STRATEGIST_ROLE) {
        require(_strategyModule != address(0), "Strategy module cannot be zero address");
        // Check if _strategyModule implements IStrategyModule (basic check, more robust off-chain)
        try IStrategyModule(_strategyModule).getCurrentValue() returns (uint256) {
            // Success, it seems to implement the interface
        } catch {
            revert("Strategy module does not implement IStrategyModule interface");
        }

        nextStrategyId++;
        strategies[nextStrategyId] = Strategy({
            id: nextStrategyId,
            proposer: msg.sender,
            moduleAddress: _strategyModule,
            name: _name,
            description: _description,
            status: StrategyStatus.Proposed,
            currentAllocation: 0,
            totalProfitGenerated: 0,
            lastReportedValue: 0,
            lastReportTimestamp: 0,
            strategistRewardAccrued: 0
        });
        strategistStrategyIds[msg.sender].push(nextStrategyId);

        nextProposalId++;
        proposals[nextProposalId] = Proposal({
            id: nextProposalId,
            proposalType: "strategy",
            proposer: msg.sender,
            startTime: block.timestamp,
            endTime: block.timestamp + params.proposalVotingPeriod,
            totalVotesFor: 0,
            totalVotesAgainst: 0,
            quorumRequired: governanceToken.totalSupply().mul(params.minStrategyVoteThresholdBps).div(BPS_DENOMINATOR),
            status: ProposalStatus.Active,
            data: abi.encode(nextStrategyId), // Store strategyId for later use
            strategyId: nextStrategyId
        });

        emit StrategyProposed(nextStrategyId, msg.sender, _strategyModule, _name);
    }

    /**
     * @dev Governance token holders (or their delegates) vote to approve or reject a proposed strategy.
     * @param _proposalId The ID of the strategy proposal.
     * @param _support True for 'for' vote, false for 'against' vote.
     */
    function voteOnStrategyProposal(uint256 _proposalId, bool _support) external {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposalType == "strategy", "Not a strategy proposal");
        require(proposal.status == ProposalStatus.Active, "Proposal is not active");
        require(block.timestamp <= proposal.endTime, "Voting period has ended");
        require(!hasVotedOnProposal[msg.sender][_proposalId], "Already voted on this proposal");

        uint256 voterPower = _getVotingPower(msg.sender);
        require(voterPower > 0, "Voter has no voting power");

        if (_support) {
            proposal.totalVotesFor = proposal.totalVotesFor.add(voterPower);
        } else {
            proposal.totalVotesAgainst = proposal.totalVotesAgainst.add(voterPower);
        }
        hasVotedOnProposal[msg.sender][_proposalId] = true;

        emit StrategyProposalVoted(_proposalId, msg.sender, _support, voterPower);
    }

    /**
     * @dev Concludes the voting period for a strategy proposal. If approved,
     *      the strategy transitions to 'Approved' status.
     *      Any governance token holder can call this after the voting period ends.
     * @param _proposalId The ID of the strategy proposal.
     */
    function finalizeStrategyProposal(uint256 _proposalId) external {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposalType == "strategy", "Not a strategy proposal");
        require(proposal.status == ProposalStatus.Active, "Proposal is not active");
        require(block.timestamp > proposal.endTime, "Voting period has not ended yet");

        if (proposal.totalVotesFor > proposal.totalVotesAgainst && proposal.totalVotesFor >= proposal.quorumRequired) {
            strategies[proposal.strategyId].status = StrategyStatus.Approved;
            proposal.status = ProposalStatus.Succeeded;

            // Initialize the strategy module with the vault token
            IStrategyModule(strategies[proposal.strategyId].moduleAddress).setVaultToken(vaultToken);

        } else {
            strategies[proposal.strategyId].status = StrategyStatus.Failed;
            proposal.status = ProposalStatus.Failed;
        }

        emit StrategyProposalFinalized(_proposalId, proposal.strategyId, proposal.status);
    }

    /**
     * @dev Governance-controlled function to allocate `vaultToken` from the protocol's treasury
     *      to an approved strategy module.
     * @param _strategyId The ID of the strategy.
     * @param _amount The amount of vaultToken to fund.
     */
    function fundStrategy(uint256 _strategyId, uint256 _amount) external onlyRole(GOVERNOR_ROLE) {
        Strategy storage strategy = strategies[_strategyId];
        require(strategy.id != 0, "Strategy does not exist");
        require(strategy.status == StrategyStatus.Approved || strategy.status == StrategyStatus.Active, "Strategy not approved or active");
        require(_amount > 0, "Amount must be greater than zero");
        require(vaultToken.balanceOf(address(this)) >= _amount, "Insufficient protocol treasury balance");

        vaultToken.transfer(strategy.moduleAddress, _amount);
        IStrategyModule(strategy.moduleAddress).deposit(_amount); // Trigger deposit on strategy module

        strategy.currentAllocation = strategy.currentAllocation.add(_amount);
        strategy.status = StrategyStatus.Active;
        strategy.lastReportedValue = IStrategyModule(strategy.moduleAddress).getCurrentValue(); // Update last reported value
        strategy.lastReportTimestamp = block.timestamp;

        emit StrategyFunded(_strategyId, _amount);
    }

    /**
     * @dev Governance-controlled function to withdraw `vaultToken` from an active
     *      strategy module back into the protocol's treasury.
     * @param _strategyId The ID of the strategy.
     * @param _amount The amount of vaultToken to defund.
     */
    function defundStrategy(uint256 _strategyId, uint256 _amount) external onlyRole(GOVERNOR_ROLE) {
        Strategy storage strategy = strategies[_strategyId];
        require(strategy.id != 0, "Strategy does not exist");
        require(strategy.status == StrategyStatus.Active || strategy.status == StrategyStatus.Paused, "Strategy not active or paused");
        require(_amount > 0, "Amount must be greater than zero");
        require(strategy.currentAllocation >= _amount, "Cannot defund more than allocated");

        uint256 actualWithdrawn = IStrategyModule(strategy.moduleAddress).withdraw(_amount);
        require(actualWithdrawn == _amount, "Strategy module failed to withdraw exact amount"); // Or handle partial withdrawal
        vaultToken.transfer(address(this), actualWithdrawn);

        strategy.currentAllocation = strategy.currentAllocation.sub(actualWithdrawn);
        if (strategy.currentAllocation == 0) {
            strategy.status = StrategyStatus.Defunded;
        }

        // Update performance metrics after defunding
        evaluateStrategyPerformance(_strategyId);

        emit StrategyDefunded(_strategyId, actualWithdrawn);
    }

    /**
     * @dev Governance can temporarily pause a strategy, preventing further funding/defunding.
     * @param _strategyId The ID of the strategy to pause.
     */
    function pauseStrategy(uint256 _strategyId) external onlyRole(GOVERNOR_ROLE) {
        Strategy storage strategy = strategies[_strategyId];
        require(strategy.id != 0, "Strategy does not exist");
        require(strategy.status == StrategyStatus.Active, "Strategy is not active");
        strategy.status = StrategyStatus.Paused;
        emit StrategyPaused(_strategyId);
    }

    /**
     * @dev Governance can unpause a previously paused strategy.
     * @param _strategyId The ID of the strategy to unpause.
     */
    function unpauseStrategy(uint256 _strategyId) external onlyRole(GOVERNOR_ROLE) {
        Strategy storage strategy = strategies[_strategyId];
        require(strategy.id != 0, "Strategy does not exist");
        require(strategy.status == StrategyStatus.Paused, "Strategy is not paused");
        strategy.status = StrategyStatus.Active;
        emit StrategyUnpaused(_strategyId);
    }

    /**
     * @dev View function returning comprehensive details about a specific strategy.
     * @param _strategyId The ID of the strategy.
     * @return Strategy details.
     */
    function getStrategyDetails(uint256 _strategyId) external view returns (Strategy memory) {
        require(_strategyId != 0 && _strategyId < nextStrategyId, "Strategy does not exist");
        return strategies[_strategyId];
    }


    // --- IV. Performance Evaluation & Adaptive Allocation ---

    /**
     * @dev Oracles report the performance (e.g., profit/loss percentage) of an active strategy.
     *      This function triggers an internal evaluation.
     * @param _strategyId The ID of the strategy.
     * @param _profitPercentage The profit/loss percentage (e.g., 1000 for 10% profit, -500 for 5% loss).
     * @param _timestamp The timestamp of the reported performance (for historical tracking).
     */
    function reportStrategyPerformance(uint256 _strategyId, int256 _profitPercentage, uint256 _timestamp) external onlyRole(ORACLE_ROLE) {
        Strategy storage strategy = strategies[_strategyId];
        require(strategy.id != 0, "Strategy does not exist");
        require(strategy.status == StrategyStatus.Active || strategy.status == StrategyStatus.Paused, "Strategy is not active or paused");
        require(_timestamp > strategy.lastReportTimestamp, "Report timestamp must be newer than last report");

        // The Oracle only reports a profit percentage based on its calculation.
        // The protocol will use this to update its internal metrics.
        // Actual value calculation is done by getCurrentValue().
        strategy.lastReportTimestamp = _timestamp;
        // In a real system, the _profitPercentage might be used to calculate a running average
        // or a specific performance score. For simplicity here, we'll use getCurrentValue().
        evaluateStrategyPerformance(_strategyId); // Trigger evaluation immediately

        emit StrategyPerformanceReported(_strategyId, _profitPercentage, _timestamp);
    }

    /**
     * @dev Internal function that processes reported performance, updates the strategy's
     *      internal score, and potentially suggests allocation adjustments.
     *      This is called by reportStrategyPerformance or can be triggered by governance.
     * @param _strategyId The ID of the strategy.
     */
    function evaluateStrategyPerformance(uint256 _strategyId) public {
        // Can be called by Oracle after reporting, or by a Governor to force re-evaluation
        if (!hasRole(ORACLE_ROLE, _msgSender()) && !hasRole(GOVERNOR_ROLE, _msgSender())) {
             require(_msgSender() == address(this), "Only oracle, governor, or internal call allowed");
        }

        Strategy storage strategy = strategies[_strategyId];
        require(strategy.id != 0, "Strategy does not exist");
        require(strategy.status == StrategyStatus.Active || strategy.status == StrategyStatus.Paused, "Strategy not active or paused");
        
        uint256 currentModuleValue = IStrategyModule(strategy.moduleAddress).getCurrentValue();
        if (strategy.lastReportedValue == 0) { // First evaluation or after full defund
            strategy.lastReportedValue = currentModuleValue;
            return;
        }

        int256 profitLoss = int256(currentModuleValue) - int256(strategy.lastReportedValue);
        
        // If profit, calculate strategist reward and protocol fees
        if (profitLoss > 0) {
            uint256 actualProfit = uint256(profitLoss);
            uint256 strategistShare = actualProfit.mul(params.strategistFeeBps).div(BPS_DENOMINATOR);
            uint256 voterShare = actualProfit.mul(params.voterFeeBps).div(BPS_DENOMINATOR);
            // uint256 treasuryShare = actualProfit.mul(params.treasuryFeeBps).div(BPS_DENOMINATOR);
            // The remaining profit stays in the strategy module, enhancing its value
            // or is brought back to the main treasury when defunded.

            strategy.strategistRewardAccrued = strategy.strategistRewardAccrued.add(strategistShare);
            voterRewardAccrued[strategy.proposer] = voterRewardAccrued[strategy.proposer].add(voterShare); // Example: reward strategist for voters
            
            // Optionally, transfer fee shares to a global fee pool here
            // For simplicity, we accrue them and they are distributed by distributeProtocolFees()
            // The actual _vaultToken for these rewards will be transferred when `distributeProtocolFees` is called.
        }

        strategy.totalProfitGenerated = strategy.totalProfitGenerated.add(uint256(profitLoss > 0 ? profitLoss : 0));
        strategy.lastReportedValue = currentModuleValue; // Update last reported value to current

        // This function doesn't automatically adjust allocations, but updates metrics
        // that governance would use to make decisions via adjustStrategyAllocation.
    }

    /**
     * @dev Governance can explicitly adjust a strategy's target allocation
     *      based on performance evaluations or other factors.
     * @param _strategyId The ID of the strategy.
     * @param _newAllocation The new target allocation for the strategy.
     */
    function adjustStrategyAllocation(uint256 _strategyId, uint256 _newAllocation) external onlyRole(GOVERNOR_ROLE) {
        Strategy storage strategy = strategies[_strategyId];
        require(strategy.id != 0, "Strategy does not exist");
        require(strategy.status == StrategyStatus.Active, "Strategy not active");

        uint256 oldAllocation = strategy.currentAllocation;

        if (_newAllocation > oldAllocation) {
            uint256 amountToFund = _newAllocation.sub(oldAllocation);
            fundStrategy(_strategyId, amountToFund);
        } else if (_newAllocation < oldAllocation) {
            uint256 amountToDefund = oldAllocation.sub(_newAllocation);
            defundStrategy(_strategyId, amountToDefund);
        }
        // If _newAllocation == oldAllocation, do nothing

        emit StrategyAllocationAdjusted(_strategyId, oldAllocation, _newAllocation);
    }

    /**
     * @dev View function returning the current capital allocated to a strategy.
     *      This is the amount of `vaultToken` that was *sent* to the strategy module.
     *      Note: `IStrategyModule(strategy.moduleAddress).getCurrentValue()` provides the actual current value including profits/losses.
     * @param _strategyId The ID of the strategy.
     * @return The current allocated amount.
     */
    function getStrategyAllocation(uint256 _strategyId) external view returns (uint256) {
        require(strategies[_strategyId].id != 0, "Strategy does not exist");
        return strategies[_strategyId].currentAllocation;
    }


    // --- V. Governance & Protocol Parameters ---

    /**
     * @dev Allows governance token holders to delegate their voting power to another address.
     * @param _delegatee The address to delegate voting power to.
     */
    function delegateVotingPower(address _delegatee) external {
        require(_delegatee != address(0), "Delegatee cannot be zero address");
        require(_delegatee != msg.sender, "Cannot delegate to self");

        address currentDelegatee = delegates[msg.sender];
        if (currentDelegatee != address(0)) {
            votingPower[currentDelegatee] = votingPower[currentDelegatee].sub(governanceToken.balanceOf(msg.sender));
        }

        delegates[msg.sender] = _delegatee;
        votingPower[_delegatee] = votingPower[_delegatee].add(governanceToken.balanceOf(msg.sender));

        emit VotingPowerDelegated(msg.sender, _delegatee);
    }

    /**
     * @dev Allows governance token holders to revoke their delegation.
     */
    function undelegateVotingPower() external {
        address currentDelegatee = delegates[msg.sender];
        require(currentDelegatee != address(0), "No active delegation");

        votingPower[currentDelegatee] = votingPower[currentDelegatee].sub(governanceToken.balanceOf(msg.sender));
        delete delegates[msg.sender];

        emit VotingPowerUndelegated(msg.sender);
    }

    /**
     * @dev Internal helper to get a user's current voting power.
     */
    function _getVotingPower(address _voter) internal view returns (uint256) {
        // If a user has delegated, their delegatee holds their voting power.
        // If a user has not delegated, their direct token balance is their voting power.
        // This simple model assumes voting power is based on balance at time of vote.
        // More advanced systems would use checkpoints for historical voting power.
        if (delegates[_voter] != address(0)) {
            return 0; // Delegator themselves have no power if delegated
        }
        return governanceToken.balanceOf(_voter).add(votingPower[_voter]); // Direct power + delegated power received
    }

    /**
     * @dev Proposes a change to a core protocol parameter.
     * @param _paramName The name of the parameter to change (e.g., "strategistFeeBps").
     * @param _newValue The new value for the parameter.
     * @param _description A description of the proposed change.
     */
    function proposeParameterChange(bytes32 _paramName, uint256 _newValue, string memory _description) external onlyRole(GOVERNOR_ROLE) {
        // Basic validation for common parameters
        if (_paramName == "strategistFeeBps" || _paramName == "voterFeeBps" || _paramName == "treasuryFeeBps") {
            // Check total fee sum after proposed change
            uint256 newStrategistFee = (_paramName == "strategistFeeBps") ? _newValue : params.strategistFeeBps;
            uint256 newVoterFee = (_paramName == "voterFeeBps") ? _newValue : params.voterFeeBps;
            uint256 newTreasuryFee = (_paramName == "treasuryFeeBps") ? _newValue : params.treasuryFeeBps;
            require(newStrategistFee.add(newVoterFee).add(newTreasuryFee) <= BPS_DENOMINATOR, "Invalid total fee sum");
        } else if (_paramName == "minStrategyVoteThresholdBps" || _paramName == "minParamVoteThresholdBps") {
            require(_newValue <= BPS_DENOMINATOR, "Threshold cannot exceed 100%");
        }

        nextProposalId++;
        proposals[nextProposalId] = Proposal({
            id: nextProposalId,
            proposalType: "parameter_change",
            proposer: msg.sender,
            startTime: block.timestamp,
            endTime: block.timestamp + params.proposalVotingPeriod,
            totalVotesFor: 0,
            totalVotesAgainst: 0,
            quorumRequired: governanceToken.totalSupply().mul(params.minParamVoteThresholdBps).div(BPS_DENOMINATOR),
            status: ProposalStatus.Active,
            data: abi.encode(_paramName, _newValue), // Encode param name and new value
            strategyId: 0 // Not applicable for parameter changes
        });

        parameterChangeProposals[nextProposalId] = ParameterChangeDetails({
            paramName: _paramName,
            newValue: _newValue,
            executionTime: 0 // Will be set after success and timelock
        });

        emit ParameterChangeProposed(nextProposalId, _paramName, _newValue);
    }

    /**
     * @dev Governance token holders vote on proposed parameter changes.
     * @param _proposalId The ID of the parameter change proposal.
     * @param _support True for 'for' vote, false for 'against' vote.
     */
    function voteOnParameterChange(uint256 _proposalId, bool _support) external {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposalType == "parameter_change", "Not a parameter change proposal");
        require(proposal.status == ProposalStatus.Active, "Proposal is not active");
        require(block.timestamp <= proposal.endTime, "Voting period has ended");
        require(!hasVotedOnProposal[msg.sender][_proposalId], "Already voted on this proposal");

        uint256 voterPower = _getVotingPower(msg.sender);
        require(voterPower > 0, "Voter has no voting power");

        if (_support) {
            proposal.totalVotesFor = proposal.totalVotesFor.add(voterPower);
        } else {
            proposal.totalVotesAgainst = proposal.totalVotesAgainst.add(voterPower);
        }
        hasVotedOnProposal[msg.sender][_proposalId] = true;

        emit ParameterChangeVoted(_proposalId, msg.sender, _support, voterPower);
    }

    /**
     * @dev Executes an approved parameter change after a timelock period.
     *      Any governance token holder can call this after the timelock.
     * @param _proposalId The ID of the parameter change proposal.
     */
    function executeParameterChange(uint256 _proposalId) external {
        Proposal storage proposal = proposals[_proposalId];
        ParameterChangeDetails storage paramDetails = parameterChangeProposals[_proposalId];
        require(proposal.proposalType == "parameter_change", "Not a parameter change proposal");

        if (proposal.status == ProposalStatus.Active) {
            // First time calling after voting period ends
            require(block.timestamp > proposal.endTime, "Voting period has not ended yet");
            if (proposal.totalVotesFor > proposal.totalVotesAgainst && proposal.totalVotesFor >= proposal.quorumRequired) {
                proposal.status = ProposalStatus.Succeeded;
                paramDetails.executionTime = block.timestamp + params.timelockDuration;
            } else {
                proposal.status = ProposalStatus.Failed;
            }
        }
        
        require(proposal.status == ProposalStatus.Succeeded, "Proposal not succeeded");
        require(block.timestamp >= paramDetails.executionTime, "Timelock has not expired");
        require(paramDetails.executionTime != 0, "Execution time not set (timelock not initiated)");

        (bytes32 paramName, uint256 newValue) = abi.decode(proposal.data, (bytes32, uint256));

        if (paramName == "minStrategyVoteThresholdBps") params.minStrategyVoteThresholdBps = newValue;
        else if (paramName == "minParamVoteThresholdBps") params.minParamVoteThresholdBps = newValue;
        else if (paramName == "proposalVotingPeriod") params.proposalVotingPeriod = newValue;
        else if (paramName == "timelockDuration") params.timelockDuration = newValue;
        else if (paramName == "strategistFeeBps") params.strategistFeeBps = newValue;
        else if (paramName == "voterFeeBps") params.voterFeeBps = newValue;
        else if (paramName == "treasuryFeeBps") params.treasuryFeeBps = newValue;
        else revert("Unknown parameter name");

        // Ensure new fee structure is valid after change
        require(params.strategistFeeBps.add(params.voterFeeBps).add(params.treasuryFeeBps) <= BPS_DENOMINATOR, "Invalid fee structure post-execution");

        proposal.status = ProposalStatus.Executed;
        emit ParameterChangeExecuted(_proposalId, paramName, newValue);
    }

    // --- VI. Incentives & Rewards ---

    /**
     * @dev Allows strategists to claim their accrued rewards based on the performance of their active strategies.
     * @param _strategyId The ID of the strategy for which to claim rewards.
     */
    function claimStrategistReward(uint256 _strategyId) external {
        Strategy storage strategy = strategies[_strategyId];
        require(strategy.id != 0, "Strategy does not exist");
        require(strategy.proposer == msg.sender, "Only the strategist can claim rewards");
        require(strategy.strategistRewardAccrued > 0, "No rewards to claim");

        uint256 rewardAmount = strategy.strategistRewardAccrued;
        strategy.strategistRewardAccrued = 0; // Reset
        
        // Transfer rewards from the protocol's vaultToken balance
        require(vaultToken.balanceOf(address(this)) >= rewardAmount, "Insufficient protocol balance for strategist rewards");
        vaultToken.transfer(msg.sender, rewardAmount);

        emit StrategistRewardClaimed(msg.sender, _strategyId, rewardAmount);
    }

    /**
     * @dev Allows active voters in governance to claim a share of protocol fees or a designated reward pool.
     *      Voter rewards are accrued via strategy evaluation and distributed by this function.
     * @param _voter The address of the voter.
     */
    function claimVoterReward(address _voter) external {
        require(_voter == msg.sender, "Can only claim own rewards");
        require(voterRewardAccrued[_voter] > 0, "No voter rewards to claim");

        uint256 rewardAmount = voterRewardAccrued[_voter];
        voterRewardAccrued[_voter] = 0; // Reset

        // Transfer rewards from the protocol's vaultToken balance
        require(vaultToken.balanceOf(address(this)) >= rewardAmount, "Insufficient protocol balance for voter rewards");
        vaultToken.transfer(msg.sender, rewardAmount);

        emit VoterRewardClaimed(msg.sender, rewardAmount);
    }

    /**
     * @dev Governance-controlled function to distribute accumulated protocol fees to strategists,
     *      voters, and the protocol treasury. This function would typically
     *      be called periodically to clear out any remaining shared profits.
     *      Note: Individual strategist/voter rewards are handled by their respective claim functions.
     *      This function distributes the portion designated for the `treasuryFeeBps`.
     *      The other fees are directly accrued to the individuals.
     */
    function distributeProtocolFees() external onlyRole(GOVERNOR_ROLE) {
        // This function could be expanded to sweep small amounts from strategies,
        // or to manage a dedicated protocol fee balance.
        // For simplicity, we assume 'treasuryFeeBps' profit is already in the main vault balance
        // or transferred explicitly to the protocol treasury address by governance.

        // This function's role might be primarily to just trigger specific events
        // or a manual transfer to the official DAO treasury if funds are accumulating
        // in the main contract directly.
        
        // For this example, let's assume protocol fees (treasuryFeeBps) are kept
        // in `address(this)` and can be withdrawn by `withdrawFunds`.
        // The `strategistRewardAccrued` and `voterRewardAccrued` are handled by their claim functions.
        
        // If there was a separate 'protocol_fee_pool' balance, we'd transfer from there.
        // As it stands, the 'treasuryFeeBps' are simply implicitly part of the
        // `vaultToken.balanceOf(address(this))` and need to be explicitly withdrawn by governance.
        
        // We'll emit an event to indicate the intent, but no direct transfer happens here
        // for the treasury portion beyond what `withdrawFunds` would do.
        
        emit ProtocolFeesDistributed(
            params.strategistFeeBps, // Signifies the share structure
            params.voterFeeBps,
            params.treasuryFeeBps
        );
    }

    /**
     * @dev Allows governance to update the distribution percentages for protocol fees.
     *      This initiates a parameter change proposal.
     * @param _strategistFeeBps Basis points for strategist share of profits.
     * @param _voterFeeBps Basis points for voter share of profits.
     * @param _treasuryFeeBps Basis points for protocol treasury share of profits.
     */
    function setFeeStructure(uint256 _strategistFeeBps, uint256 _voterFeeBps, uint256 _treasuryFeeBps) external onlyRole(GOVERNOR_ROLE) {
        // This function will trigger parameter change proposals for each fee component.
        // More realistically, it would propose a 'FeeStructure' struct change.
        // For simplicity, we'll assume a direct change here for demo, but
        // in a production system, this would go through the parameter change proposal flow.
        require(_strategistFeeBps.add(_voterFeeBps).add(_treasuryFeeBps) <= BPS_DENOMINATOR, "Invalid total fee sum");
        
        params.strategistFeeBps = _strategistFeeBps;
        params.voterFeeBps = _voterFeeBps;
        params.treasuryFeeBps = _treasuryFeeBps;

        emit FeeStructureUpdated(_strategistFeeBps, _voterFeeBps, _treasuryFeeBps);
    }
}
```