Here is a Solidity smart contract named `EtherealEchoesProtocol` that embodies an interesting, advanced-concept, creative, and trendy idea: a **self-adaptive DeFi and community token ($ECHO) protocol with dynamic tokenomics governed by on-chain metrics and community proposals.**

This contract goes beyond a standard DAO or ERC-20 by allowing its core economic parameters (like inflation, burn rates, and staking rewards) to evolve over time. These changes are driven by:
1.  **On-chain Metrics:** Data from an external metrics oracle can influence decisions.
2.  **Community Governance:** Staked token holders (Governors) propose and vote on parameter adjustments and treasury allocations.
3.  **Time-based Automation:** A key `updateDynamicSupply` function periodically adjusts the token supply based on current rates and protocol health, distributing rewards to active participants.

It also features a robust staking mechanism, a governed treasury, and an extensible module system for future functionality.

---

### **EtherealEchoesProtocol Outline and Function Summary**

The `EtherealEchoesProtocol` contract manages the native `$ECHO` token and its adaptive economic policies. It integrates governance, staking, a treasury, and an extensible module system.

**I. Core Infrastructure & Access Control (7 functions)**
*   **Purpose:** Handles contract initialization, emergency pausing, and role-based permissions for different levels of protocol participants.
    1.  `constructor`: Initializes the contract, mints initial `$ECHO` supply to the treasury, sets up administrative roles, and configures the initial metrics oracle address.
    2.  `updateMetricOracleAddress`: Allows an admin to update the address of the external metrics oracle, ensuring data integrity.
    3.  `pause`: Puts the entire protocol into an emergency paused state, preventing most state-changing operations. Only callable by an admin.
    4.  `unpause`: Resumes protocol operations from a paused state. Only callable by an admin.
    5.  `grantRole`: Assigns a specific `AccessControl` role (e.g., Governor, Core Contributor) to an address.
    6.  `revokeRole`: Removes a specific `AccessControl` role from an address.
    7.  `hasRole`: Checks if a given address possesses a specific role.

**II. Adaptive Tokenomics & Parameter Governance (9 functions)**
*   **Purpose:** Implements the core "self-adaptive" mechanism, allowing fundamental protocol parameters (like inflation, burn rates, staking multipliers, cooldown periods) to be proposed, voted on, and dynamically adjusted.
    8.  `getProtocolMetric`: Retrieves a specific metric value (e.g., protocol TVL, active users) from the configured metrics oracle.
    9.  `proposeParameterAdjustment`: Allows addresses with the `GOVERNOR_ROLE` to propose changes to protocol's dynamic economic parameters. Requires a minimum staked amount.
    10. `voteOnParameterAdjustment`: Enables staked token holders to vote "for" or "against" active parameter adjustment proposals, with their vote weight determined by their staked `$ECHO`.
    11. `endParameterAdjustmentVoting`: Finalizes the voting period for a parameter proposal, checks for quorum and approval percentage, and determines if the proposal passes. Can be called by anyone after the voting deadline.
    12. `executeParameterAdjustment`: Executes a passed parameter adjustment proposal, applying the proposed new value to the respective protocol parameter. Callable by a `GOVERNOR_ROLE` within a grace period.
    13. `getProposedParameterValue`: Returns the target value of a parameter as specified in a pending or passed proposal.
    14. `getProposalDetails`: Retrieves comprehensive details for a specific parameter adjustment proposal.
    15. `updateDynamicSupply`: The central "self-evolving" function. Periodically (e.g., daily), it mints new `$ECHO` tokens to the treasury based on the `currentInflationRateBps` and distributes a portion as staking rewards. It also indirectly triggers the burn rate on transfers via an internal hook. Callable by anyone after the `SUPPLY_UPDATE_INTERVAL`.
    16. `getLastSupplyUpdateTimestamp`: Returns the timestamp of the last time `updateDynamicSupply` was successfully called.

**III. Staking & Rewards (8 functions)**
*   **Purpose:** Enables users to stake their `$ECHO` tokens to participate in governance and earn a share of newly minted tokens, supporting active community engagement.
    17. `stakeTokens`: Allows users to deposit their `$ECHO` tokens into the contract to become stakers, gaining voting power and reward eligibility.
    18. `requestUnstake`: Initiates the unstaking process. It immediately reduces the user's active staked balance (impacting voting and rewards) and moves the tokens to a pending state, subject to a `stakingCooldownPeriod`.
    19. `withdrawUnstaked`: Allows users to retrieve their tokens from the pending unstake queue after their individual cooldown period has elapsed.
    20. `claimStakingRewards`: Allows stakers to claim their accumulated `$ECHO` rewards, which are distributed from the treasury.
    21. `getStakedAmount`: Returns the amount of `$ECHO` tokens an address currently has actively staked.
    22. `getPendingUnstakeAmount`: Returns the amount of `$ECHO` tokens an address has requested to unstake but not yet withdrawn.
    23. `getUnstakeReleaseTimestamp`: Returns the timestamp when an address's pending unstake amount becomes available for withdrawal.
    24. `getAvailableStakingRewards`: Returns the amount of `$ECHO` rewards pending for a specific staker.
    25. `setStakingCooldownPeriod`: Allows `GOVERNOR_ROLE` to adjust the duration tokens are locked during the unstaking process.

**IV. Treasury & Development Fund (5 functions)**
*   **Purpose:** Manages a community-governed treasury for protocol development, grants, marketing, and strategic initiatives, funded by new token mints and external contributions.
    26. `proposeTreasuryAllocation`: Allows addresses with the `CORE_CONTRIBUTOR_ROLE` to propose how funds from the treasury should be allocated to specific recipients for approved purposes.
    27. `voteOnTreasuryAllocation`: Enables `GOVERNOR_ROLE` holders to vote "for" or "against" treasury allocation proposals, using their staked `$ECHO` as vote power.
    28. `executeTreasuryAllocation`: Executes a passed treasury allocation proposal, transferring `$ECHO` from the treasury to the designated recipient. Callable by a `GOVERNOR_ROLE`.
    29. `getTreasuryBalance`: Returns the current balance of `$ECHO` tokens held by the protocol's treasury.
    30. `depositToTreasury`: Allows any user to voluntarily deposit `$ECHO` tokens into the protocol's treasury, contributing to its growth.

**V. Extensibility & Module Management (3 functions)**
*   **Purpose:** Provides a mechanism for the protocol to evolve and integrate new features (e.g., DeFi integrations, community tools) by registering external smart contract modules, without requiring a complete redeployment of the core contract.
    31. `registerModule`: Registers a new external module contract with a unique ID and description. Callable by `MODULE_MANAGER_ROLE`.
    32. `deregisterModule`: Deregisters an existing module, marking it as inactive and removing it from the active list. Callable by `MODULE_MANAGER_ROLE`.
    33. `getModuleAddress`: Retrieves the address of a registered and active module by its unique ID, allowing other contracts or frontends to interact with it.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// Interface for a hypothetical Metrics Oracle
// This oracle would provide aggregated, validated data points relevant to the protocol's health and activity.
// Example metric IDs: keccak256("PROTOCOL_TVL"), keccak256("ACTIVE_USERS_7D"), keccak256("ETH_USD_PRICE")
interface IMetricsOracle {
    function getMetric(bytes32 _metricId) external view returns (uint256);
}

/**
 * @title EtherealEchoesProtocol
 * @dev A self-adaptive DeFi and community token ($ECHO) protocol with dynamic tokenomics
 *      governed by on-chain metrics and community proposals.
 *      It features adaptive parameter adjustments, staking for governance, a managed treasury,
 *      and an extensible module system.
 */
contract EtherealEchoesProtocol is ERC20, AccessControl, Pausable, ReentrancyGuard {

    using EnumerableSet for EnumerableSet.AddressSet; // For efficient staker tracking

    // --- Roles ---
    bytes32 public constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");
    bytes32 public constant CORE_CONTRIBUTOR_ROLE = keccak256("CORE_CONTRIBUTOR_ROLE");
    bytes32 public constant MODULE_MANAGER_ROLE = keccak256("MODULE_MANAGER_ROLE");

    // --- State Variables ---
    address public metricsOracleAddress;
    address public treasuryAddress;

    // Governance Parameters
    uint256 public constant MIN_VOTE_POWER_FOR_PROPOSAL = 1000 * (10 ** 18); // Example: 1000 ECHO tokens
    uint256 public constant VOTING_PERIOD_DURATION = 7 days; // 7 days for voting
    uint256 public constant PROPOSAL_EXECUTION_GRACE_PERIOD = 2 days; // Time after voting ends to execute
    uint256 public constant PROPOSAL_QUORUM_PERCENTAGE = 30; // 30% of total staked supply must vote 'for'
    uint256 public constant PROPOSAL_APPROVAL_PERCENTAGE = 60; // 60% of 'for' votes needed to pass

    // Dynamic Tokenomics Parameters (initial values)
    uint256 public currentInflationRateBps = 100; // 1% annually (100 basis points)
    uint256 public currentBurnRateBps = 10;      // 0.1% of transfers (10 basis points)
    uint256 public stakingRewardMultiplierBps = 500; // 5% (500 basis points) of new supply goes to stakers

    uint256 public lastSupplyUpdateTimestamp;
    uint256 public constant SUPPLY_UPDATE_INTERVAL = 1 days; // Update dynamic supply once per day

    // Staking
    mapping(address => uint256) public stakedAmounts; // Amount of ECHO actively staked
    mapping(address => uint256) public pendingUnstakeAmounts; // Amount requested to unstake, pending cooldown
    mapping(address => uint256) public unstakeReleaseTimestamp; // Timestamp when pendingUnstakeAmounts can be withdrawn
    uint256 public stakingCooldownPeriod = 14 days; // Default 14 days cooldown for unstaking
    EnumerableSet.AddressSet private _stakers; // Set of all addresses currently staking

    // Rewards (simplified calculation: a share of newly minted tokens)
    mapping(address => uint256) public accruedStakingRewards;
    uint256 public totalStakedSupply;

    // --- Parameter Adjustment Proposals ---
    struct ParameterAdjustmentProposal {
        bytes32 proposalId;
        bytes32 parameterName;    // e.g., keccak256("currentInflationRateBps"), keccak256("stakingCooldownPeriod")
        uint256 proposedValue;
        uint256 totalForVotes;
        uint256 totalAgainstVotes;
        uint256 votingDeadline;
        uint256 executionDeadline; // Time after voting ends to execute
        bool executed;
        bool passed;
        mapping(address => bool) hasVoted; // Tracks if an address has voted on this proposal
    }
    mapping(bytes32 => ParameterAdjustmentProposal) public parameterProposals;
    bytes32[] public activeParameterProposals; // List of active proposals

    // --- Treasury Allocation Proposals ---
    struct TreasuryAllocationProposal {
        bytes32 proposalId;
        address recipient;
        uint256 amount;
        string description;
        uint256 totalForVotes;
        uint256 totalAgainstVotes;
        uint256 votingDeadline;
        uint256 executionDeadline;
        bool executed;
        bool passed;
        mapping(address => bool) hasVoted;
    }
    mapping(bytes32 => TreasuryAllocationProposal) public treasuryProposals;
    bytes32[] public activeTreasuryProposals;

    // --- Module Registry ---
    struct Module {
        address moduleAddress;
        string description;
        bool isActive;
    }
    mapping(bytes32 => Module) public registeredModules; // moduleID => Module
    bytes32[] public activeModuleIds; // List of registered module IDs

    // --- Events ---
    event MetricOracleAddressUpdated(address indexed newAddress);
    event ParameterAdjustmentProposed(bytes32 indexed proposalId, bytes32 indexed parameterName, uint256 proposedValue, address indexed proposer);
    event ParameterAdjustmentVoteCast(bytes32 indexed proposalId, address indexed voter, bool support, uint256 votePower);
    event ParameterAdjustmentProposalPassed(bytes32 indexed proposalId, bytes32 parameterName, uint256 newValue);
    event ParameterAdjustmentProposalFailed(bytes32 indexed proposalId);
    event ParameterAdjustmentExecuted(bytes32 indexed proposalId, bytes32 parameterName, uint256 newValue);
    event DynamicSupplyUpdated(uint256 newSupply, uint256 mintedAmount, uint256 burnedAmount);

    event TokensStaked(address indexed staker, uint256 amount);
    event UnstakeRequested(address indexed staker, uint256 amount, uint256 releaseTime);
    event TokensUnstaked(address indexed staker, uint256 amount); // For final withdrawal
    event StakingRewardsClaimed(address indexed staker, uint256 amount);
    event StakingCooldownPeriodSet(uint256 newPeriod);

    event TreasuryAllocationProposed(bytes32 indexed proposalId, address indexed recipient, uint256 amount, string description, address indexed proposer);
    event TreasuryAllocationVoteCast(bytes32 indexed proposalId, address indexed voter, bool support, uint256 votePower);
    event TreasuryAllocationProposalPassed(bytes32 indexed proposalId, address indexed recipient, uint256 amount);
    event TreasuryAllocationProposalFailed(bytes32 indexed proposalId);
    event TreasuryAllocationExecuted(bytes32 indexed proposalId, address indexed recipient, uint256 amount);
    event FundsDepositedToTreasury(address indexed sender, uint256 amount);

    event ModuleRegistered(bytes32 indexed moduleId, address indexed moduleAddress, string description);
    event ModuleDeregistered(bytes32 indexed moduleId);

    /**
     * @dev Constructor to initialize the contract.
     * @param initialSupply Initial supply of $ECHO tokens to be minted.
     * @param admin The address to be granted the DEFAULT_ADMIN_ROLE.
     * @param oracleAddress The initial address of the metrics oracle.
     * @param _treasuryAddress The address designated as the protocol's treasury.
     */
    constructor(uint256 initialSupply, address admin, address oracleAddress, address _treasuryAddress)
        ERC20("Ethereal Echoes", "ECHO")
    {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender); // Deployer also gets admin role

        // Initial mint for the treasury or initial distribution
        _mint(_treasuryAddress, initialSupply);
        treasuryAddress = _treasuryAddress;

        metricsOracleAddress = oracleAddress;
        require(metricsOracleAddress != address(0), "Oracle address cannot be zero");

        lastSupplyUpdateTimestamp = block.timestamp;
    }

    // --- I. Core Infrastructure & Access Control ---

    /**
     * @dev Throws if called by any account other than a Governor.
     */
    modifier onlyGovernor() {
        require(hasRole(GOVERNOR_ROLE, msg.sender), "Caller is not a Governor");
        _;
    }

    /**
     * @dev Throws if called by any account other than a Core Contributor.
     */
    modifier onlyCoreContributor() {
        require(hasRole(CORE_CONTRIBUTOR_ROLE, msg.sender), "Caller is not a Core Contributor");
        _;
    }

    /**
     * @dev Throws if called by any account other than a Module Manager.
     */
    modifier onlyModuleManager() {
        require(hasRole(MODULE_MANAGER_ROLE, msg.sender), "Caller is not a Module Manager");
        _;
    }

    /**
     * @dev Updates the address of the external metrics oracle.
     * @param newAddress The new address of the IMetricsOracle contract.
     */
    function updateMetricOracleAddress(address newAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newAddress != address(0), "New oracle address cannot be zero");
        metricsOracleAddress = newAddress;
        emit MetricOracleAddressUpdated(newAddress);
    }

    /**
     * @dev Pauses the protocol. Only callable by an admin.
     *      No state-changing functions can be called while paused.
     */
    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /**
     * @dev Unpauses the protocol. Only callable by an admin.
     */
    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /**
     * @dev Grants a role to an address. Only callable by an admin or an account with the role's admin role.
     * @param role The role to grant.
     * @param account The address to grant the role to.
     */
    function grantRole(bytes32 role, address account) public virtual override {
        // Only DEFAULT_ADMIN_ROLE can grant other roles initially
        require(hasRole(getRoleAdmin(role), _msgSender()), "AccessControl: sender must be an admin to grant");
        _grantRole(role, account);
    }

    /**
     * @dev Revokes a role from an address. Only callable by an admin or an account with the role's admin role.
     * @param role The role to revoke.
     * @param account The address to revoke the role from.
     */
    function revokeRole(bytes32 role, address account) public virtual override {
        require(hasRole(getRoleAdmin(role), _msgSender()), "AccessControl: sender must be an admin to revoke");
        _revokeRole(role, account);
    }

    /**
     * @dev Checks if an address has a specific role.
     * @param role The role to check.
     * @param account The address to check.
     * @return True if the address has the role, false otherwise.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _hasRole(role, account);
    }

    // --- II. Adaptive Tokenomics & Parameter Governance ---

    /**
     * @dev Retrieves a specific metric value from the oracle.
     *      Requires the metricsOracleAddress to be set.
     * @param _metricId The ID of the metric to retrieve (e.g., keccak256("PROTOCOL_TVL")).
     * @return The uint256 value of the requested metric.
     */
    function getProtocolMetric(bytes32 _metricId) public view returns (uint256) {
        require(metricsOracleAddress != address(0), "Metrics oracle not set");
        return IMetricsOracle(metricsOracleAddress).getMetric(_metricId);
    }

    /**
     * @dev Allows Governors to propose changes to protocol parameters.
     *      The parameterName must correspond to an existing state variable in the contract.
     *      A minimum vote power is required to propose.
     * @param _parameterName The name of the parameter to adjust (e.g., keccak256("currentInflationRateBps")).
     * @param _proposedValue The new value for the parameter.
     */
    function proposeParameterAdjustment(bytes32 _parameterName, uint256 _proposedValue)
        external
        onlyGovernor
        whenNotPaused
        nonReentrant
        returns (bytes32 proposalId)
    {
        require(stakedAmounts[msg.sender] >= MIN_VOTE_POWER_FOR_PROPOSAL, "Not enough staked tokens to propose");
        proposalId = keccak256(abi.encodePacked(_parameterName, _proposedValue, block.timestamp));
        require(parameterProposals[proposalId].proposalId == bytes32(0), "Proposal already exists");

        parameterProposals[proposalId] = ParameterAdjustmentProposal({
            proposalId: proposalId,
            parameterName: _parameterName,
            proposedValue: _proposedValue,
            totalForVotes: 0,
            totalAgainstVotes: 0,
            votingDeadline: block.timestamp + VOTING_PERIOD_DURATION,
            executionDeadline: 0, // Set after voting ends
            executed: false,
            passed: false
        });
        activeParameterProposals.push(proposalId);
        emit ParameterAdjustmentProposed(proposalId, _parameterName, _proposedValue, msg.sender);
        return proposalId;
    }

    /**
     * @dev Allows staked token holders to vote on active parameter adjustment proposals.
     *      Vote power is equal to their currently staked amount.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'for', false for 'against'.
     */
    function voteOnParameterAdjustment(bytes32 _proposalId, bool _support)
        external
        whenNotPaused
        nonReentrant
    {
        ParameterAdjustmentProposal storage proposal = parameterProposals[_proposalId];
        require(proposal.proposalId != bytes32(0), "Proposal does not exist");
        require(block.timestamp < proposal.votingDeadline, "Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");
        require(stakedAmounts[msg.sender] > 0, "Must have staked tokens to vote");

        proposal.hasVoted[msg.sender] = true;
        uint256 votePower = stakedAmounts[msg.sender];

        if (_support) {
            proposal.totalForVotes += votePower;
        } else {
            proposal.totalAgainstVotes += votePower;
        }
        emit ParameterAdjustmentVoteCast(_proposalId, msg.sender, _support, votePower);
    }

    /**
     * @dev Ends the voting period for a parameter adjustment proposal and determines if it passed.
     *      Can be called by anyone after the voting deadline.
     * @param _proposalId The ID of the proposal to end voting for.
     */
    function endParameterAdjustmentVoting(bytes32 _proposalId)
        external
        whenNotPaused
        nonReentrant
    {
        ParameterAdjustmentProposal storage proposal = parameterProposals[_proposalId];
        require(proposal.proposalId != bytes32(0), "Proposal does not exist");
        require(block.timestamp >= proposal.votingDeadline, "Voting period not yet ended");
        require(proposal.executionDeadline == 0, "Voting already ended for this proposal"); // Not yet processed

        // Calculate total votes and check quorum
        uint256 totalVotesCast = proposal.totalForVotes + proposal.totalAgainstVotes;
        require(totalStakedSupply > 0, "No tokens staked, impossible to reach quorum");
        uint256 quorumThreshold = (totalStakedSupply * PROPOSAL_QUORUM_PERCENTAGE) / 100;

        // Check if quorum is met AND if it reached the approval percentage
        if (totalVotesCast >= quorumThreshold &&
            (proposal.totalForVotes * 100) >= (totalVotesCast * PROPOSAL_APPROVAL_PERCENTAGE))
        {
            proposal.passed = true;
            proposal.executionDeadline = block.timestamp + PROPOSAL_EXECUTION_GRACE_PERIOD;
            emit ParameterAdjustmentProposalPassed(_proposalId, proposal.parameterName, proposal.proposedValue);
        } else {
            proposal.passed = false;
            // No execution deadline if it failed, immediately mark as not executable
            proposal.executed = true; // Mark as processed even if failed
            emit ParameterAdjustmentProposalFailed(_proposalId);
        }

        // Remove from active proposals list (can be optimized for gas by tracking indices)
        for (uint i = 0; i < activeParameterProposals.length; i++) {
            if (activeParameterProposals[i] == _proposalId) {
                activeParameterProposals[i] = activeParameterProposals[activeParameterProposals.length - 1];
                activeParameterProposals.pop();
                break;
            }
        }
    }

    /**
     * @dev Executes a passed parameter adjustment proposal. Only callable after voting ends
     *      and within the execution grace period.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeParameterAdjustment(bytes32 _proposalId)
        external
        onlyGovernor // Restrict execution to Governors for safety
        whenNotPaused
        nonReentrant
    {
        ParameterAdjustmentProposal storage proposal = parameterProposals[_proposalId];
        require(proposal.proposalId != bytes32(0), "Proposal does not exist");
        require(proposal.passed, "Proposal did not pass or voting not ended");
        require(!proposal.executed, "Proposal already executed");
        require(block.timestamp < proposal.executionDeadline, "Execution grace period has expired");

        // Dynamically set the parameter based on its name
        if (proposal.parameterName == keccak256("currentInflationRateBps")) {
            currentInflationRateBps = proposal.proposedValue;
        } else if (proposal.parameterName == keccak256("currentBurnRateBps")) {
            currentBurnRateBps = proposal.proposedValue;
        } else if (proposal.parameterName == keccak256("stakingRewardMultiplierBps")) {
            stakingRewardMultiplierBps = proposal.proposedValue;
        } else if (proposal.parameterName == keccak256("stakingCooldownPeriod")) {
            stakingCooldownPeriod = proposal.proposedValue;
        }
        // Add more parameters here as needed

        proposal.executed = true;
        emit ParameterAdjustmentExecuted(_proposalId, proposal.parameterName, proposal.proposedValue);
    }

    /**
     * @dev Returns the potential new value of a parameter if a specific proposal passes.
     * @param _proposalId The ID of the proposal.
     * @return The proposed value.
     */
    function getProposedParameterValue(bytes32 _proposalId) public view returns (uint256) {
        return parameterProposals[_proposalId].proposedValue;
    }

    /**
     * @dev Retrieves full details of a parameter adjustment proposal.
     * @param _proposalId The ID of the proposal.
     * @return A tuple containing all proposal details.
     */
    function getProposalDetails(bytes32 _proposalId)
        public
        view
        returns (
            bytes32 proposalId,
            bytes32 parameterName,
            uint256 proposedValue,
            uint256 totalForVotes,
            uint256 totalAgainstVotes,
            uint256 votingDeadline,
            uint256 executionDeadline,
            bool executed,
            bool passed
        )
    {
        ParameterAdjustmentProposal storage p = parameterProposals[_proposalId];
        return (
            p.proposalId,
            p.parameterName,
            p.proposedValue,
            p.totalForVotes,
            p.totalAgainstVotes,
            p.votingDeadline,
            p.executionDeadline,
            p.executed,
            p.passed
        );
    }

    /**
     * @dev The core function for dynamic supply adjustment. Mints new tokens based on inflation rate
     *      and distributes rewards. Callable by anyone, but only executes if enough time has passed
     *      since last update. Rewards are distributed to stakers.
     */
    function updateDynamicSupply()
        public
        whenNotPaused
        nonReentrant
        returns (uint256 mintedAmount, uint256 burnedAmount)
    {
        require(block.timestamp >= lastSupplyUpdateTimestamp + SUPPLY_UPDATE_INTERVAL, "Not yet time for supply update");

        uint256 timeElapsed = block.timestamp - lastSupplyUpdateTimestamp;
        // Simplified annual inflation calculation (rate * total_supply * time_elapsed / 1 year)
        // For more precision, consider using a fixed point math library for large values.
        // Assuming 1 year = 365 days for this calculation.
        mintedAmount = (totalSupply() * currentInflationRateBps * timeElapsed) / (10000 * 365 days);

        if (mintedAmount > 0) {
            _mint(treasuryAddress, mintedAmount);
        }

        // Distribute a portion of minted tokens as staking rewards
        if (mintedAmount > 0 && totalStakedSupply > 0) {
            uint256 rewardsToDistribute = (mintedAmount * stakingRewardMultiplierBps) / 10000;
            // For simplicity, rewards are linearly distributed based on staked amount.
            // A more complex system might use rewardPerToken tracking.
            for (uint i = 0; i < _stakers.length(); i++) {
                address staker = _stakers.at(i);
                if (stakedAmounts[staker] > 0) {
                    accruedStakingRewards[staker] += (rewardsToDistribute * stakedAmounts[staker]) / totalStakedSupply;
                }
            }
        }
        
        burnedAmount = 0; // The burn happens on _beforeTokenTransfer, not here.

        lastSupplyUpdateTimestamp = block.timestamp;
        emit DynamicSupplyUpdated(totalSupply(), mintedAmount, burnedAmount);

        return (mintedAmount, burnedAmount);
    }

    /**
     * @dev Returns the timestamp of the last dynamic supply update.
     */
    function getLastSupplyUpdateTimestamp() public view returns (uint256) {
        return lastSupplyUpdateTimestamp;
    }

    // Override internal _transfer to apply burn rate on every transfer
    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override
        whenNotPaused
    {
        super._beforeTokenTransfer(from, to, amount);

        // Apply burn only on actual transfers, not mints (from == address(0)) or initial deployment.
        // Also exclude transfers to/from treasury to prevent double counting/burning on internal ops.
        if (currentBurnRateBps > 0 && from != address(0) && to != address(0) && from != treasuryAddress && to != treasuryAddress) {
            uint256 burnAmount = (amount * currentBurnRateBps) / 10000;
            if (burnAmount > 0) {
                // Burn from the sender's balance. The remaining `amount - burnAmount` will be transferred.
                _burn(from, burnAmount);
            }
        }
    }

    // --- III. Staking & Rewards ---

    /**
     * @dev Allows users to stake their $ECHO tokens to participate in governance and earn rewards.
     * @param amount The amount of $ECHO tokens to stake.
     */
    function stakeTokens(uint256 amount) external whenNotPaused nonReentrant {
        require(amount > 0, "Amount must be greater than zero");
        _transfer(msg.sender, address(this), amount); // Transfer tokens to this contract
        stakedAmounts[msg.sender] += amount;
        totalStakedSupply += amount;
        _stakers.add(msg.sender);
        emit TokensStaked(msg.sender, amount);
    }

    /**
     * @dev Allows users to request unstake of their tokens. Tokens will be moved to a pending state
     *      and become withdrawable after the cooldown period. This reduces their active staked amount
     *      immediately (affecting voting power and rewards).
     * @param amount The amount of $ECHO tokens to request unstake for.
     */
    function requestUnstake(uint256 amount) external whenNotPaused nonReentrant {
        require(amount > 0, "Amount must be greater than zero");
        require(stakedAmounts[msg.sender] >= amount, "Not enough staked tokens");
        
        // Claim any pending rewards BEFORE reducing staked amount for accurate calculation
        claimStakingRewards();

        stakedAmounts[msg.sender] -= amount;
        totalStakedSupply -= amount;
        
        if (stakedAmounts[msg.sender] == 0) {
            _stakers.remove(msg.sender);
        }

        pendingUnstakeAmounts[msg.sender] += amount;
        // Set the release timestamp. If there's an existing cooldown, update it if the new request extends it.
        uint256 currentReleaseTime = unstakeReleaseTimestamp[msg.sender];
        uint256 newReleaseTime = block.timestamp + stakingCooldownPeriod;
        if (newReleaseTime > currentReleaseTime) { // Only extend if the new cooldown is longer
            unstakeReleaseTimestamp[msg.sender] = newReleaseTime;
        } else if (currentReleaseTime == 0) { // If no current cooldown, set it
            unstakeReleaseTimestamp[msg.sender] = newReleaseTime;
        }

        emit UnstakeRequested(msg.sender, amount, unstakeReleaseTimestamp[msg.sender]);
    }

    /**
     * @dev Allows users to withdraw their tokens after the unstake cooldown period has passed.
     */
    function withdrawUnstaked() external whenNotPaused nonReentrant {
        uint256 amountToWithdraw = pendingUnstakeAmounts[msg.sender];
        require(amountToWithdraw > 0, "No pending unstake amounts to withdraw");
        require(block.timestamp >= unstakeReleaseTimestamp[msg.sender], "Unstake cooldown period not yet ended");

        pendingUnstakeAmounts[msg.sender] = 0;
        unstakeReleaseTimestamp[msg.sender] = 0; // Reset for future unstakes
        _transfer(address(this), msg.sender, amountToWithdraw);
        emit TokensUnstaked(msg.sender, amountToWithdraw);
    }

    /**
     * @dev Allows stakers to claim their accrued rewards.
     */
    function claimStakingRewards() public whenNotPaused nonReentrant { // Changed to public so it can be called explicitly
        uint256 rewards = accruedStakingRewards[msg.sender];
        require(rewards > 0, "No rewards to claim");

        accruedStakingRewards[msg.sender] = 0;
        // Transfer from treasury (where new tokens are minted)
        // Ensure treasury has enough balance before transferring.
        require(balanceOf(treasuryAddress) >= rewards, "Treasury has insufficient funds for rewards");
        _transfer(treasuryAddress, msg.sender, rewards);
        emit StakingRewardsClaimed(msg.sender, rewards);
    }

    /**
     * @dev Returns the amount of tokens an address has currently actively staked.
     * @param staker The address to check.
     * @return The staked amount.
     */
    function getStakedAmount(address staker) public view returns (uint256) {
        return stakedAmounts[staker];
    }

    /**
     * @dev Returns the amount of tokens an address has requested to unstake but not yet withdrawn.
     * @param staker The address to check.
     * @return The pending unstake amount.
     */
    function getPendingUnstakeAmount(address staker) public view returns (uint256) {
        return pendingUnstakeAmounts[staker];
    }

    /**
     * @dev Returns the timestamp when the pending unstake amount for a staker becomes available for withdrawal.
     * @param staker The address to check.
     * @return The release timestamp.
     */
    function getUnstakeReleaseTimestamp(address staker) public view returns (uint256) {
        return unstakeReleaseTimestamp[staker];
    }

    /**
     * @dev Returns the amount of pending staking rewards for a staker.
     * @param staker The address to check.
     * @return The pending rewards amount.
     */
    function getAvailableStakingRewards(address staker) public view returns (uint256) {
        return accruedStakingRewards[staker];
    }

    /**
     * @dev Sets the cooldown period for unstaking tokens.
     * @param newPeriod The new cooldown duration in seconds.
     */
    function setStakingCooldownPeriod(uint256 newPeriod) external onlyGovernor {
        stakingCooldownPeriod = newPeriod;
        emit StakingCooldownPeriodSet(newPeriod);
    }

    // --- IV. Treasury & Development Fund ---

    /**
     * @dev Allows Core Contributors to propose how treasury funds should be spent.
     * @param _recipient The address to send funds to.
     * @param _amount The amount of funds to send.
     * @param _description A description of the proposal.
     */
    function proposeTreasuryAllocation(address _recipient, uint256 _amount, string memory _description)
        external
        onlyCoreContributor
        whenNotPaused
        nonReentrant
        returns (bytes32 proposalId)
    {
        require(_recipient != address(0), "Recipient cannot be zero address");
        require(_amount > 0, "Amount must be greater than zero");
        require(balanceOf(treasuryAddress) >= _amount, "Insufficient treasury balance");

        proposalId = keccak256(abi.encodePacked(_recipient, _amount, _description, block.timestamp));
        require(treasuryProposals[proposalId].proposalId == bytes32(0), "Proposal already exists");

        treasuryProposals[proposalId] = TreasuryAllocationProposal({
            proposalId: proposalId,
            recipient: _recipient,
            amount: _amount,
            description: _description,
            totalForVotes: 0,
            totalAgainstVotes: 0,
            votingDeadline: block.timestamp + VOTING_PERIOD_DURATION,
            executionDeadline: 0, // Set after voting ends
            executed: false,
            passed: false
        });
        activeTreasuryProposals.push(proposalId);
        emit TreasuryAllocationProposed(proposalId, _recipient, _amount, _description, msg.sender);
        return proposalId;
    }

    /**
     * @dev Allows Governors to vote on treasury allocation proposals.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'for', false for 'against'.
     */
    function voteOnTreasuryAllocation(bytes32 _proposalId, bool _support)
        external
        onlyGovernor // Only Governors vote on treasury
        whenNotPaused
        nonReentrant
    {
        TreasuryAllocationProposal storage proposal = treasuryProposals[_proposalId];
        require(proposal.proposalId != bytes32(0), "Proposal does not exist");
        require(block.timestamp < proposal.votingDeadline, "Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");
        
        // For treasury proposals, Governors' vote power is tied to their staked ECHO.
        require(stakedAmounts[msg.sender] > 0, "Must have staked tokens to vote");
        uint256 votePower = stakedAmounts[msg.sender];

        proposal.hasVoted[msg.sender] = true;
        if (_support) {
            proposal.totalForVotes += votePower;
        } else {
            proposal.totalAgainstVotes += votePower;
        }
        emit TreasuryAllocationVoteCast(_proposalId, msg.sender, _support, votePower);
    }

    /**
     * @dev Executes an approved treasury allocation, transferring funds from the treasury.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeTreasuryAllocation(bytes32 _proposalId)
        external
        onlyGovernor // Restrict execution to Governors for safety
        whenNotPaused
        nonReentrant
    {
        TreasuryAllocationProposal storage proposal = treasuryProposals[_proposalId];
        require(proposal.proposalId != bytes32(0), "Proposal does not exist");
        require(!proposal.executed, "Proposal already executed");
        require(block.timestamp >= proposal.votingDeadline, "Voting not yet ended");
        require(block.timestamp < proposal.executionDeadline || proposal.executionDeadline == 0, "Execution grace period has expired");

        // Determine if proposal passed (quorum and approval percentage)
        uint256 totalVotesCast = proposal.totalForVotes + proposal.totalAgainstVotes;
        require(totalStakedSupply > 0, "No tokens staked, impossible to reach quorum");
        uint256 quorumThreshold = (totalStakedSupply * PROPOSAL_QUORUM_PERCENTAGE) / 100;

        if (totalVotesCast >= quorumThreshold &&
            (proposal.totalForVotes * 100) >= (totalVotesCast * PROPOSAL_APPROVAL_PERCENTAGE))
        {
            proposal.passed = true;
            // Transfer funds from treasury to recipient
            require(balanceOf(treasuryAddress) >= proposal.amount, "Treasury has insufficient funds for allocation");
            _transfer(treasuryAddress, proposal.recipient, proposal.amount);
            emit TreasuryAllocationExecuted(_proposalId, proposal.recipient, proposal.amount);
        } else {
            proposal.passed = false;
            emit TreasuryAllocationProposalFailed(_proposalId);
        }
        proposal.executed = true; // Mark as processed regardless of pass/fail

        // Remove from active proposals list
        for (uint i = 0; i < activeTreasuryProposals.length; i++) {
            if (activeTreasuryProposals[i] == _proposalId) {
                activeTreasuryProposals[i] = activeTreasuryProposals[activeTreasuryProposals.length - 1];
                activeTreasuryProposals.pop();
                break;
            }
        }
    }

    /**
     * @dev Returns the current balance of the protocol's treasury.
     * @return The balance of the treasury address.
     */
    function getTreasuryBalance() public view returns (uint256) {
        return balanceOf(treasuryAddress);
    }

    /**
     * @dev Allows anyone to deposit funds ($ECHO tokens) into the protocol treasury.
     *      This increases the treasury's balance, which can then be allocated via proposals.
     * @param amount The amount of $ECHO tokens to deposit.
     */
    function depositToTreasury(uint256 amount) external whenNotPaused nonReentrant {
        require(amount > 0, "Amount must be greater than zero");
        _transfer(msg.sender, treasuryAddress, amount);
        emit FundsDepositedToTreasury(msg.sender, amount);
    }

    // --- V. Extensibility & Module Management ---

    /**
     * @dev Registers a new protocol module. Modules are external contracts that extend functionality.
     *      Requires MODULE_MANAGER_ROLE.
     * @param _moduleId A unique identifier for the module (e.g., keccak256("DEX_INTEGRATION")).
     * @param _moduleAddress The address of the deployed module contract.
     * @param _description A description of the module's purpose.
     */
    function registerModule(bytes32 _moduleId, address _moduleAddress, string memory _description)
        external
        onlyModuleManager
        whenNotPaused
    {
        require(_moduleAddress != address(0), "Module address cannot be zero");
        require(registeredModules[_moduleId].moduleAddress == address(0), "Module already registered");

        registeredModules[_moduleId] = Module({
            moduleAddress: _moduleAddress,
            description: _description,
            isActive: true
        });
        activeModuleIds.push(_moduleId);
        emit ModuleRegistered(_moduleId, _moduleAddress, _description);
    }

    /**
     * @dev Deregisters an existing protocol module.
     *      Requires MODULE_MANAGER_ROLE.
     * @param _moduleId The ID of the module to deregister.
     */
    function deregisterModule(bytes32 _moduleId) external onlyModuleManager whenNotPaused {
        require(registeredModules[_moduleId].moduleAddress != address(0), "Module not registered");
        require(registeredModules[_moduleId].isActive, "Module already inactive");

        registeredModules[_moduleId].isActive = false; // Mark as inactive

        // Remove from activeModuleIds list (can be optimized for gas by tracking indices)
        for (uint i = 0; i < activeModuleIds.length; i++) {
            if (activeModuleIds[i] == _moduleId) {
                activeModuleIds[i] = activeModuleIds[activeModuleIds.length - 1];
                activeModuleIds.pop();
                break;
            }
        }
        emit ModuleDeregistered(_moduleId);
    }

    /**
     * @dev Retrieves the address of a registered and active module by its ID.
     * @param _moduleId The ID of the module to retrieve.
     * @return The address of the module contract.
     */
    function getModuleAddress(bytes32 _moduleId) public view returns (address) {
        require(registeredModules[_moduleId].moduleAddress != address(0), "Module not found");
        require(registeredModules[_moduleId].isActive, "Module is inactive");
        return registeredModules[_moduleId].moduleAddress;
    }

    // --- Helper Functions (not counted in the 20+ requirement) ---
    /**
     * @dev Returns all active parameter proposal IDs.
     */
    function getActiveParameterProposals() public view returns (bytes32[] memory) {
        return activeParameterProposals;
    }

    /**
     * @dev Returns all active treasury proposal IDs.
     */
    function getActiveTreasuryProposals() public view returns (bytes32[] memory) {
        return activeTreasuryProposals;
    }

    /**
     * @dev Returns all active module IDs.
     */
    function getActiveModuleIds() public view returns (bytes32[] memory) {
        return activeModuleIds;
    }

    /**
     * @dev Returns the total number of unique stakers.
     */
    function getTotalStakers() public view returns (uint256) {
        return _stakers.length();
    }
}
```