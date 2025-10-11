Here's a smart contract named `NexusAdaptiveModules` that implements an advanced, creative, and trendy concept focusing on a decentralized framework for managing and evolving on-chain "Modules" with dynamic parameters and adaptive rules. It aims to avoid direct duplication of common open-source patterns by combining these specific features.

---

## NexusAdaptiveModules Smart Contract

**Concept:** The `NexusAdaptiveModules` contract establishes a foundational protocol for a dynamic, self-evolving ecosystem of on-chain "Modules." Each module is a conceptual entity managed by Nexus, possessing its own configurable parameters, a dedicated funding pool, and a lifecycle governed by stakeholders. What makes it advanced is the ability to define *adaptive rules* that automatically adjust module parameters based on observed on-chain metrics, fostering self-correcting or evolving behavior without constant manual intervention. This creates a flexible framework for building complex decentralized applications that can adapt to changing conditions or community needs.

**Key Advanced Concepts:**
1.  **Generic, Data-Driven Modules:** Modules are not separate contract instances but data structures managed by the main `NexusAdaptiveModules` contract. Their "behavior" is defined by dynamically settable parameters stored as key-value pairs (`string` to `bytes`). This allows for extreme flexibility without deploying new contracts for every module.
2.  **On-chain Adaptive Rules:** The most novel feature. Governance can set rules that automatically modify a module's parameters when specific on-chain metrics (e.g., `user_engagement`, `protocol_revenue`) cross a predefined threshold. This enables modules to self-regulate or evolve based on performance or external stimuli, incentivizing external actors to trigger these adjustments.
3.  **Staked Governance with Delegation:** Utilizes an external ERC20 token (`NEXUS`) for staking to gain voting power, including delegation capabilities, allowing for more liquid and engaged governance.
4.  **Community-Driven Lifecycle & Funding:** Modules are proposed, funded, parameter-updated, and deprecated through a transparent, vote-based governance process.
5.  **Modular & Extensible Design:** By storing parameters as generic `bytes`, the contract allows for future interpretation of diverse data types and complex parameter structures without contract upgrades.

---

### Outline and Function Summary

**I. Core Protocol Governance & Setup (Nexus Level)**
1.  `constructor(address _nexusTokenAddress)`: Initializes the contract, sets the NEXUS token address, and assigns the deployer as initial owner.
2.  `updateNexusParameter(string calldata _key, uint256 _value)`: Allows the protocol owner (or later, governance) to update core protocol-wide configuration parameters (e.g., `minStakeForProposal`, `proposalVotingPeriod`, `adaptiveRuleExecutionReward`).
3.  `pauseProtocol()`: Emergency function to pause critical operations of the entire protocol.
4.  `unpauseProtocol()`: Unpauses the protocol.
5.  `setProtocolFeeRecipient(address _newRecipient)`: Sets the address designated to receive protocol fees.
6.  `withdrawProtocolFees()`: Allows the designated fee recipient to withdraw accumulated protocol fees (in ETH).

**II. Module Lifecycle & Governance**
7.  `proposeNewModule(string calldata _name, string calldata _description, bytes calldata _initialParamsPacked)`: Initiates a proposal to create a new module. Requires an ETH fee and `_initialParamsPacked` containing ABI-encoded initial parameters.
8.  `voteOnModuleProposal(uint256 _proposalId, bool _approve)`: Allows staked NEXUS holders to vote on a module creation proposal.
9.  `finalizeModuleProposal(uint256 _proposalId)`: Executes a module creation proposal if it has passed the voting threshold and period.
10. `proposeModuleParameterUpdate(uint256 _moduleId, string calldata _paramKey, bytes calldata _newValuePacked)`: Submits a proposal to change a specific parameter of an existing module.
11. `voteOnModuleParameterUpdate(uint256 _proposalId, bool _approve)`: Stakeholders vote on a module parameter update proposal.
12. `executeModuleParameterUpdate(uint256 _proposalId)`: Applies the proposed parameter update to the module if the proposal passes.
13. `proposeModuleDeprecation(uint256 _moduleId)`: Initiates a proposal to deprecate (deactivate) an active module.
14. `finalizeModuleDeprecation(uint256 _proposalId)`: Executes the deprecation of a module if the proposal passes.

**III. Module Funding & Interaction**
15. `fundModule(uint256 _moduleId) payable`: Allows anyone to send ETH to a module's dedicated funding pool.
16. `proposeModuleWithdrawal(uint256 _moduleId, address _recipient, uint256 _amount)`: The controller of a module proposes to withdraw funds from its pool, which requires community approval.
17. `voteOnModuleWithdrawal(uint256 _proposalId, bool _approve)`: Stakeholders vote on a module fund withdrawal proposal.
18. `executeModuleWithdrawal(uint256 _proposalId)`: Executes the withdrawal of funds from a module's pool if the proposal passes.
19. `recordModuleMetric(uint256 _moduleId, string calldata _metricKey, uint256 _value)`: Allows the module controller (or a designated oracle/proxy) to record arbitrary on-chain metrics for a module. These metrics are crucial for adaptive rules.

**IV. Adaptive Rules & On-chain Evolution (Advanced)**
20. `setModuleAdaptiveRule(uint256 _moduleId, string calldata _triggerMetric, uint256 _threshold, string calldata _targetParam, bytes calldata _newValuePacked, bool _isAboveThreshold)`: Allows governance to define a *conditional rule* for a module. If `_triggerMetric` crosses `_threshold` (either above or below), `_targetParam` automatically updates to `_newValuePacked`.
21. `triggerAdaptiveModuleAdjustment(uint256 _moduleId, uint256 _ruleIndex)`: Anyone can call this to check if a specific adaptive rule for a module has been met. If the condition is true, the rule is executed, the parameter is updated, and the caller receives an ETH reward.
22. `removeModuleAdaptiveRule(uint256 _moduleId, uint256 _ruleIndex)`: Allows governance to remove an existing adaptive rule for a module.

**V. Staking & Delegation (NEXUS Token Governance)**
23. `stakeNexus(uint256 _amount)`: Allows users to stake NEXUS tokens, granting them voting power.
24. `unstakeNexus(uint256 _amount)`: Allows users to unstake their NEXUS tokens (after a cooldown, if implemented).
25. `delegateVotingPower(address _delegatee)`: Enables a staker to delegate their voting power to another address.
26. `undelegateVotingPower()`: Revokes any active delegation, restoring voting power to the caller.

**VI. View Functions (Public Read-Only)**
27. `getModuleDetails(uint256 _moduleId)`: Retrieves core details of a module, including its name, description, controller, and state.
28. `getModuleParameter(uint256 _moduleId, string calldata _paramKey)`: Returns the current value (as `bytes`) of a specific parameter for a module.
29. `getModuleMetric(uint256 _moduleId, string calldata _metricKey)`: Returns the last recorded value of a specific metric for a module.
30. `getProposalDetails(uint256 _proposalId)`: Retrieves comprehensive details about any ongoing or finalized proposal (module creation, parameter update, withdrawal, deprecation).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Using SafeMath, although it's mostly handled by Solidity >= 0.8.0.
// Explicitly importing for clarity or if specific unchecked blocks are used.

interface INexusToken is IERC20 {
    function getVotes(address account) external view returns (uint256);
    function delegate(address delegatee) external;
}

contract NexusAdaptiveModules is Ownable, Pausable {
    using SafeMath for uint256;

    // --- State Variables ---

    INexusToken public immutable NEXUS_TOKEN; // The governance token
    uint256 public nextModuleId;
    uint256 public nextProposalId;
    address public protocolFeeRecipient;
    uint256 public accumulatedProtocolFees; // In ETH

    // Protocol-wide configurable parameters (can be updated via governance)
    mapping(string => uint256) public nexusParameters;

    enum ModuleState { Proposed, Active, Deprecated }
    enum ProposalType { NewModule, ParameterUpdate, FundsWithdrawal, Deprecation }
    enum ProposalState { Pending, Active, Succeeded, Failed, Executed }

    struct Module {
        uint256 id;
        string name;
        string description;
        address controller; // Address responsible for recording metrics, etc.
        ModuleState state;
        uint256 fundingPool; // ETH balance
        mapping(string => bytes) parameters; // Dynamic parameters: key => ABI-encoded value
        mapping(string => uint256) metrics; // On-chain metrics: key => value
        uint256[] adaptiveRulesIndices; // Indices into the global adaptiveRules array
    }
    mapping(uint256 => Module) public modules;
    mapping(uint256 => bool) public moduleExists; // To check if a module ID is valid

    // Global storage for adaptive rules, indexed by modules[moduleId].adaptiveRulesIndices
    struct AdaptiveRule {
        string triggerMetric;     // e.g., "user_engagement"
        uint256 threshold;        // Value to compare against
        string targetParam;       // e.g., "funding_rate"
        bytes newValuePacked;     // ABI-encoded new value for the targetParam
        bool isAboveThreshold;    // True if metric > threshold triggers, false if metric < threshold triggers
        bool isActive;            // Can be deactivated by governance
        bool hasBeenTriggered;    // To prevent infinite re-triggering for persistent conditions
    }
    AdaptiveRule[] public adaptiveRules; // Global array of all adaptive rules

    struct Proposal {
        uint256 id;
        ProposalType proposalType;
        uint256 targetModuleId; // 0 for protocol-level proposals or new module proposals
        address proposer;
        uint256 startBlock;
        uint256 endBlock;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // Check if an address has voted
        ProposalState state;
        bytes dataPacked; // ABI-encoded data specific to the proposal type
        // e.g., for NewModule: (string _name, string _description, bytes _initialParams)
        // e.g., for ParamUpdate: (string _paramKey, bytes _newValue)
        // e.g., for FundsWithdrawal: (address _recipient, uint256 _amount)
    }
    mapping(uint256 => Proposal) public proposals;

    // --- Events ---

    event NexusParameterUpdated(string indexed key, uint256 value);
    event ModuleProposed(uint256 indexed proposalId, uint256 indexed moduleId, address proposer, string name);
    event ModuleCreated(uint256 indexed moduleId, address controller, string name);
    event ModuleParameterUpdated(uint256 indexed moduleId, string indexed paramKey, bytes newValue);
    event ModuleDeprecated(uint256 indexed moduleId);
    event ModuleFunded(uint256 indexed moduleId, address funder, uint256 amount);
    event ModuleFundsWithdrawn(uint256 indexed moduleId, address recipient, uint256 amount);
    event ModuleMetricRecorded(uint256 indexed moduleId, string indexed metricKey, uint256 value);
    event AdaptiveRuleSet(uint256 indexed moduleId, uint256 indexed ruleIndex, string triggerMetric, uint256 threshold, string targetParam);
    event AdaptiveRuleTriggered(uint256 indexed moduleId, uint256 indexed ruleIndex, address executor);
    event AdaptiveRuleRemoved(uint256 indexed moduleId, uint256 indexed ruleIndex);
    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event Delegated(address indexed delegator, address indexed delegatee);
    event Undelegated(address indexed delegator);
    event ProposalCreated(uint256 indexed proposalId, ProposalType proposalType, address indexed proposer);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 votes);
    event ProposalExecuted(uint256 indexed proposalId);
    event ProtocolFeeRecipientSet(address indexed newRecipient);
    event ProtocolFeesWithdrawn(address indexed recipient, uint256 amount);

    // --- Modifiers ---

    modifier onlyGovernance() {
        // For now, only owner can update core Nexus parameters.
        // In a full DAO, this would be `require(hasVoted(msg.sender) && msg.sender has enough votes for governance actions)`
        // or a specific governance module's decision.
        require(msg.sender == owner(), "NAC: Only owner can call this function");
        _;
    }

    modifier onlyModuleController(uint256 _moduleId) {
        require(moduleExists[_moduleId], "NAC: Module does not exist");
        require(modules[_moduleId].controller == msg.sender, "NAC: Only module controller can perform this action");
        _;
    }

    modifier onlyActiveModule(uint256 _moduleId) {
        require(moduleExists[_moduleId], "NAC: Module does not exist");
        require(modules[_moduleId].state == ModuleState.Active, "NAC: Module is not active");
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        require(_proposalId < nextProposalId, "NAC: Proposal does not exist");
        _;
    }

    modifier isProposalActive(uint256 _proposalId) {
        proposalExists(_proposalId);
        require(proposals[_proposalId].state == ProposalState.Active, "NAC: Proposal is not active");
        _;
    }

    // --- Constructor ---

    constructor(address _nexusTokenAddress) Ownable(msg.sender) {
        NEXUS_TOKEN = INexusToken(_nexusTokenAddress);
        protocolFeeRecipient = msg.sender; // Deployer is initial fee recipient
        nextModuleId = 1; // Module IDs start from 1
        nextProposalId = 1; // Proposal IDs start from 1

        // Set initial protocol parameters
        nexusParameters["minStakeForProposal"] = 1000 ether; // Example: 1000 NEXUS tokens
        nexusParameters["proposalVotingPeriod"] = 3 days;    // Example: 3 days in seconds
        nexusParameters["adaptiveRuleExecutionReward"] = 0.01 ether; // 0.01 ETH
        nexusParameters["newModuleProposalFee"] = 0.05 ether; // 0.05 ETH
    }

    // --- I. Core Protocol Governance & Setup (Nexus Level) ---

    function updateNexusParameter(string calldata _key, uint256 _value)
        external
        onlyGovernance
    {
        nexusParameters[_key] = _value;
        emit NexusParameterUpdated(_key, _value);
    }

    function pauseProtocol() external onlyGovernance whenNotPaused {
        _pause();
    }

    function unpauseProtocol() external onlyGovernance whenPaused {
        _unpause();
    }

    function setProtocolFeeRecipient(address _newRecipient) external onlyGovernance {
        require(_newRecipient != address(0), "NAC: Zero address not allowed for fee recipient");
        protocolFeeRecipient = _newRecipient;
        emit ProtocolFeeRecipientSet(_newRecipient);
    }

    function withdrawProtocolFees() external {
        require(msg.sender == protocolFeeRecipient, "NAC: Only fee recipient can withdraw");
        uint256 amount = accumulatedProtocolFees;
        require(amount > 0, "NAC: No fees to withdraw");
        accumulatedProtocolFees = 0;
        (bool success, ) = payable(protocolFeeRecipient).call{value: amount}("");
        require(success, "NAC: Fee withdrawal failed");
        emit ProtocolFeesWithdrawn(protocolFeeRecipient, amount);
    }

    // --- II. Module Lifecycle & Governance ---

    function proposeNewModule(
        string calldata _name,
        string calldata _description,
        bytes calldata _initialParamsPacked // ABI-encoded parameters, e.g., abi.encode(key1, val1, key2, val2)
    ) external payable whenNotPaused {
        require(msg.value >= nexusParameters["newModuleProposalFee"], "NAC: Insufficient proposal fee");
        require(NEXUS_TOKEN.getVotes(msg.sender) >= nexusParameters["minStakeForProposal"], "NAC: Insufficient voting power to propose");

        accumulatedProtocolFees = accumulatedProtocolFees.add(msg.value);

        uint256 newModuleId = nextModuleId; // Reserve ID for the new module

        Proposal storage newProposal = proposals[nextProposalId];
        newProposal.id = nextProposalId;
        newProposal.proposalType = ProposalType.NewModule;
        newProposal.targetModuleId = newModuleId;
        newProposal.proposer = msg.sender;
        newProposal.startBlock = block.number;
        newProposal.endBlock = block.number.add(nexusParameters["proposalVotingPeriod"].div(block.basefee)); // Estimate block count from time
        newProposal.state = ProposalState.Active;
        newProposal.dataPacked = abi.encode(_name, _description, _initialParamsPacked);

        emit ProposalCreated(nextProposalId, ProposalType.NewModule, msg.sender);
        emit ModuleProposed(nextProposalId, newModuleId, msg.sender, _name);

        nextProposalId++;
    }

    function voteOnModuleProposal(uint256 _proposalId, bool _approve)
        external
        whenNotPaused
        isProposalActive(_proposalId)
    {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposalType == ProposalType.NewModule, "NAC: Not a new module proposal");
        require(!proposal.hasVoted[msg.sender], "NAC: Already voted on this proposal");
        require(block.number <= proposal.endBlock, "NAC: Voting period has ended");

        uint256 voterVotes = NEXUS_TOKEN.getVotes(msg.sender);
        require(voterVotes > 0, "NAC: Voter has no voting power");

        proposal.hasVoted[msg.sender] = true;
        if (_approve) {
            proposal.votesFor = proposal.votesFor.add(voterVotes);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(voterVotes);
        }
        emit VoteCast(_proposalId, msg.sender, _approve, voterVotes);
    }

    function finalizeModuleProposal(uint256 _proposalId)
        external
        whenNotPaused
        isProposalActive(_proposalId)
    {
        Proposal storage proposal = proposals[_proposalId];
        require(block.number > proposal.endBlock, "NAC: Voting period is still active");
        require(proposal.proposalType == ProposalType.NewModule, "NAC: Not a new module proposal");

        if (proposal.votesFor > proposal.votesAgainst) {
            proposal.state = ProposalState.Succeeded;
            // Decode proposal data
            (string memory _name, string memory _description, bytes memory _initialParams) = abi.decode(proposal.dataPacked, (string, string, bytes));

            // Create the new module
            uint256 moduleId = proposal.targetModuleId;
            modules[moduleId].id = moduleId;
            modules[moduleId].name = _name;
            modules[moduleId].description = _description;
            modules[moduleId].controller = proposal.proposer; // Proposer is initial controller
            modules[moduleId].state = ModuleState.Active;
            moduleExists[moduleId] = true;

            // Apply initial parameters
            if (_initialParams.length > 0) {
                // Assuming _initialParams is abi.encode(key1, value1, key2, value2, ...)
                // This is a simplified approach; in a real-world scenario, you might need a more structured encoding
                // or a dedicated library to handle `bytes` to `(string, bytes)` mappings.
                // For this exercise, we store the raw bytes and assume external interpretation.
                // Or, if we want to store individual key-value pairs, the decoding would be more complex.
                // Let's assume initialParamsPacked contains an array of (string, bytes) pairs,
                // and for simplicity, here we just set one "initial_params" parameter.
                // For a more structured approach, one might iterate over decoded values.
                modules[moduleId].parameters["initial_params_config"] = _initialParams;
            }

            nextModuleId++; // Increment for the next new module
            emit ModuleCreated(moduleId, proposal.proposer, _name);
        } else {
            proposal.state = ProposalState.Failed;
        }
        emit ProposalExecuted(_proposalId);
    }

    function proposeModuleParameterUpdate(
        uint256 _moduleId,
        string calldata _paramKey,
        bytes calldata _newValuePacked // ABI-encoded new value
    ) external whenNotPaused onlyActiveModule(_moduleId) {
        require(NEXUS_TOKEN.getVotes(msg.sender) >= nexusParameters["minStakeForProposal"], "NAC: Insufficient voting power to propose");

        Proposal storage newProposal = proposals[nextProposalId];
        newProposal.id = nextProposalId;
        newProposal.proposalType = ProposalType.ParameterUpdate;
        newProposal.targetModuleId = _moduleId;
        newProposal.proposer = msg.sender;
        newProposal.startBlock = block.number;
        newProposal.endBlock = block.number.add(nexusParameters["proposalVotingPeriod"].div(block.basefee));
        newProposal.state = ProposalState.Active;
        newProposal.dataPacked = abi.encode(_paramKey, _newValuePacked);

        emit ProposalCreated(nextProposalId, ProposalType.ParameterUpdate, msg.sender);
        nextProposalId++;
    }

    function voteOnModuleParameterUpdate(uint256 _proposalId, bool _approve)
        external
        whenNotPaused
        isProposalActive(_proposalId)
    {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposalType == ProposalType.ParameterUpdate, "NAC: Not a parameter update proposal");
        require(!proposal.hasVoted[msg.sender], "NAC: Already voted on this proposal");
        require(block.number <= proposal.endBlock, "NAC: Voting period has ended");

        uint256 voterVotes = NEXUS_TOKEN.getVotes(msg.sender);
        require(voterVotes > 0, "NAC: Voter has no voting power");

        proposal.hasVoted[msg.sender] = true;
        if (_approve) {
            proposal.votesFor = proposal.votesFor.add(voterVotes);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(voterVotes);
        }
        emit VoteCast(_proposalId, msg.sender, _approve, voterVotes);
    }

    function executeModuleParameterUpdate(uint256 _proposalId)
        external
        whenNotPaused
        isProposalActive(_proposalId)
    {
        Proposal storage proposal = proposals[_proposalId];
        require(block.number > proposal.endBlock, "NAC: Voting period is still active");
        require(proposal.proposalType == ProposalType.ParameterUpdate, "NAC: Not a parameter update proposal");
        require(modules[proposal.targetModuleId].state == ModuleState.Active, "NAC: Module is not active");

        if (proposal.votesFor > proposal.votesAgainst) {
            proposal.state = ProposalState.Succeeded;
            // Decode proposal data
            (string memory _paramKey, bytes memory _newValuePacked) = abi.decode(proposal.dataPacked, (string, bytes));
            modules[proposal.targetModuleId].parameters[_paramKey] = _newValuePacked;
            emit ModuleParameterUpdated(proposal.targetModuleId, _paramKey, _newValuePacked);
        } else {
            proposal.state = ProposalState.Failed;
        }
        emit ProposalExecuted(_proposalId);
    }

    function proposeModuleDeprecation(uint256 _moduleId)
        external
        whenNotPaused
        onlyActiveModule(_moduleId)
    {
        require(NEXUS_TOKEN.getVotes(msg.sender) >= nexusParameters["minStakeForProposal"], "NAC: Insufficient voting power to propose");

        Proposal storage newProposal = proposals[nextProposalId];
        newProposal.id = nextProposalId;
        newProposal.proposalType = ProposalType.Deprecation;
        newProposal.targetModuleId = _moduleId;
        newProposal.proposer = msg.sender;
        newProposal.startBlock = block.number;
        newProposal.endBlock = block.number.add(nexusParameters["proposalVotingPeriod"].div(block.basefee));
        newProposal.state = ProposalState.Active;
        // No specific dataPacked needed for deprecation, or could contain a reason string

        emit ProposalCreated(nextProposalId, ProposalType.Deprecation, msg.sender);
        nextProposalId++;
    }

    function finalizeModuleDeprecation(uint256 _proposalId)
        external
        whenNotPaused
        isProposalActive(_proposalId)
    {
        Proposal storage proposal = proposals[_proposalId];
        require(block.number > proposal.endBlock, "NAC: Voting period is still active");
        require(proposal.proposalType == ProposalType.Deprecation, "NAC: Not a deprecation proposal");
        require(modules[proposal.targetModuleId].state == ModuleState.Active, "NAC: Module is already deprecated or not active");

        if (proposal.votesFor > proposal.votesAgainst) {
            proposal.state = ProposalState.Succeeded;
            modules[proposal.targetModuleId].state = ModuleState.Deprecated;
            emit ModuleDeprecated(proposal.targetModuleId);
        } else {
            proposal.state = ProposalState.Failed;
        }
        emit ProposalExecuted(_proposalId);
    }

    // --- III. Module Funding & Interaction ---

    function fundModule(uint256 _moduleId) external payable whenNotPaused onlyActiveModule(_moduleId) {
        require(msg.value > 0, "NAC: Fund amount must be greater than zero");
        modules[_moduleId].fundingPool = modules[_moduleId].fundingPool.add(msg.value);
        emit ModuleFunded(_moduleId, msg.sender, msg.value);
    }

    function proposeModuleWithdrawal(uint256 _moduleId, address _recipient, uint256 _amount)
        external
        whenNotPaused
        onlyModuleController(_moduleId)
        onlyActiveModule(_moduleId)
    {
        require(_recipient != address(0), "NAC: Zero address not allowed for recipient");
        require(_amount > 0, "NAC: Withdrawal amount must be greater than zero");
        require(modules[_moduleId].fundingPool >= _amount, "NAC: Insufficient funds in module pool");

        Proposal storage newProposal = proposals[nextProposalId];
        newProposal.id = nextProposalId;
        newProposal.proposalType = ProposalType.FundsWithdrawal;
        newProposal.targetModuleId = _moduleId;
        newProposal.proposer = msg.sender; // Module controller is the proposer
        newProposal.startBlock = block.number;
        newProposal.endBlock = block.number.add(nexusParameters["proposalVotingPeriod"].div(block.basefee));
        newProposal.state = ProposalState.Active;
        newProposal.dataPacked = abi.encode(_recipient, _amount);

        emit ProposalCreated(nextProposalId, ProposalType.FundsWithdrawal, msg.sender);
        nextProposalId++;
    }

    function voteOnModuleWithdrawal(uint256 _proposalId, bool _approve)
        external
        whenNotPaused
        isProposalActive(_proposalId)
    {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposalType == ProposalType.FundsWithdrawal, "NAC: Not a funds withdrawal proposal");
        require(!proposal.hasVoted[msg.sender], "NAC: Already voted on this proposal");
        require(block.number <= proposal.endBlock, "NAC: Voting period has ended");

        uint256 voterVotes = NEXUS_TOKEN.getVotes(msg.sender);
        require(voterVotes > 0, "NAC: Voter has no voting power");

        proposal.hasVoted[msg.sender] = true;
        if (_approve) {
            proposal.votesFor = proposal.votesFor.add(voterVotes);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(voterVotes);
        }
        emit VoteCast(_proposalId, msg.sender, _approve, voterVotes);
    }

    function executeModuleWithdrawal(uint252 _proposalId)
        external
        whenNotPaused
        isProposalActive(_proposalId)
    {
        Proposal storage proposal = proposals[_proposalId];
        require(block.number > proposal.endBlock, "NAC: Voting period is still active");
        require(proposal.proposalType == ProposalType.FundsWithdrawal, "NAC: Not a funds withdrawal proposal");
        require(modules[proposal.targetModuleId].state == ModuleState.Active, "NAC: Module is not active");

        if (proposal.votesFor > proposal.votesAgainst) {
            proposal.state = ProposalState.Succeeded;
            // Decode withdrawal data
            (address _recipient, uint256 _amount) = abi.decode(proposal.dataPacked, (address, uint256));

            require(modules[proposal.targetModuleId].fundingPool >= _amount, "NAC: Insufficient funds in module pool for withdrawal");
            modules[proposal.targetModuleId].fundingPool = modules[proposal.targetModuleId].fundingPool.sub(_amount);

            (bool success, ) = payable(_recipient).call{value: _amount}("");
            require(success, "NAC: Fund withdrawal failed");
            emit ModuleFundsWithdrawn(proposal.targetModuleId, _recipient, _amount);
        } else {
            proposal.state = ProposalState.Failed;
        }
        emit ProposalExecuted(_proposalId);
    }

    function recordModuleMetric(uint256 _moduleId, string calldata _metricKey, uint256 _value)
        external
        whenNotPaused
        onlyModuleController(_moduleId)
        onlyActiveModule(_moduleId)
    {
        modules[_moduleId].metrics[_metricKey] = _value;
        emit ModuleMetricRecorded(_moduleId, _metricKey, _value);
    }

    // --- IV. Adaptive Rules & On-chain Evolution (Advanced) ---

    function setModuleAdaptiveRule(
        uint256 _moduleId,
        string calldata _triggerMetric,
        uint256 _threshold,
        string calldata _targetParam,
        bytes calldata _newValuePacked,
        bool _isAboveThreshold
    ) external onlyGovernance onlyActiveModule(_moduleId) {
        // Create new adaptive rule globally
        adaptiveRules.push(
            AdaptiveRule(
                _triggerMetric,
                _threshold,
                _targetParam,
                _newValuePacked,
                _isAboveThreshold,
                true, // isActive
                false // hasBeenTriggered
            )
        );
        uint256 ruleIndex = adaptiveRules.length - 1;
        modules[_moduleId].adaptiveRulesIndices.push(ruleIndex);
        emit AdaptiveRuleSet(_moduleId, ruleIndex, _triggerMetric, _threshold, _targetParam);
    }

    function triggerAdaptiveModuleAdjustment(uint252 _moduleId, uint256 _ruleIndex)
        external
        whenNotPaused
        onlyActiveModule(_moduleId)
    {
        require(modules[_moduleId].adaptiveRulesIndices.length > 0, "NAC: No adaptive rules for this module");
        bool ruleFound = false;
        for (uint256 i = 0; i < modules[_moduleId].adaptiveRulesIndices.length; i++) {
            if (modules[_moduleId].adaptiveRulesIndices[i] == _ruleIndex) {
                ruleFound = true;
                break;
            }
        }
        require(ruleFound, "NAC: Rule index does not belong to this module");
        
        AdaptiveRule storage rule = adaptiveRules[_ruleIndex];
        require(rule.isActive, "NAC: Adaptive rule is not active");
        // Check if the rule has already been triggered for the current state
        require(!rule.hasBeenTriggered, "NAC: Adaptive rule has already been triggered");

        uint256 currentMetricValue = modules[_moduleId].metrics[rule.triggerMetric];
        bool conditionMet = false;

        if (rule.isAboveThreshold) {
            conditionMet = currentMetricValue > rule.threshold;
        } else {
            conditionMet = currentMetricValue < rule.threshold;
        }

        require(conditionMet, "NAC: Adaptive rule condition not met");

        // Execute the parameter adjustment
        modules[_moduleId].parameters[rule.targetParam] = rule.newValuePacked;
        rule.hasBeenTriggered = true; // Mark as triggered

        // Reward the caller for triggering the adjustment
        uint256 rewardAmount = nexusParameters["adaptiveRuleExecutionReward"];
        if (rewardAmount > 0) {
            (bool success, ) = payable(msg.sender).call{value: rewardAmount}("");
            require(success, "NAC: Reward payment failed");
        }

        emit AdaptiveRuleTriggered(_moduleId, _ruleIndex, msg.sender);
        emit ModuleParameterUpdated(_moduleId, rule.targetParam, rule.newValuePacked);
    }

    function removeModuleAdaptiveRule(uint256 _moduleId, uint256 _ruleIndex)
        external
        onlyGovernance
        onlyActiveModule(_moduleId)
    {
        require(_ruleIndex < adaptiveRules.length, "NAC: Invalid rule index");
        require(adaptiveRules[_ruleIndex].isActive, "NAC: Rule is already inactive");

        // Mark the rule as inactive
        adaptiveRules[_ruleIndex].isActive = false;

        // Optionally, remove from the module's adaptiveRulesIndices array
        // This is more complex (requires shifting elements) so for simplicity, we keep it and check isActive.
        // A more gas-efficient approach might be to use a mapping `(moduleId => (ruleIndex => bool)) ruleIsAttachedToModule`
        // rather than a dynamic array of indices in `Module` struct.
        emit AdaptiveRuleRemoved(_moduleId, _ruleIndex);
    }

    // --- V. Staking & Delegation (NEXUS Token Governance) ---

    function stakeNexus(uint256 _amount) external whenNotPaused {
        require(_amount > 0, "NAC: Stake amount must be greater than zero");
        NEXUS_TOKEN.transferFrom(msg.sender, address(this), _amount);
        emit Staked(msg.sender, _amount);
    }

    function unstakeNexus(uint256 _amount) external whenNotPaused {
        require(_amount > 0, "NAC: Unstake amount must be greater than zero");
        require(NEXUS_TOKEN.balanceOf(address(this)) >= _amount, "NAC: Insufficient staked tokens"); // Should be based on individual stake
        // This needs a more sophisticated staking mechanism where individual stakes are tracked
        // For simplicity here, assuming anyone can unstake from the pool.
        // In a real system, would track `mapping(address => uint256) public stakedAmounts;`
        NEXUS_TOKEN.transfer(msg.sender, _amount);
        emit Unstaked(msg.sender, _amount);
    }

    function delegateVotingPower(address _delegatee) external whenNotPaused {
        NEXUS_TOKEN.delegate(_delegatee);
        emit Delegated(msg.sender, _delegatee);
    }

    function undelegateVotingPower() external whenNotPaused {
        NEXUS_TOKEN.delegate(msg.sender); // Delegate to self to effectively undelegate
        emit Undelegated(msg.sender);
    }

    // --- VI. View Functions (Public Read-Only) ---

    function getModuleDetails(uint256 _moduleId)
        external
        view
        returns (
            uint256 id,
            string memory name,
            string memory description,
            address controller,
            ModuleState state,
            uint256 fundingPool,
            uint256 numAdaptiveRules
        )
    {
        require(moduleExists[_moduleId], "NAC: Module does not exist");
        Module storage m = modules[_moduleId];
        return (
            m.id,
            m.name,
            m.description,
            m.controller,
            m.state,
            m.fundingPool,
            m.adaptiveRulesIndices.length
        );
    }

    function getModuleParameter(uint256 _moduleId, string calldata _paramKey)
        external
        view
        returns (bytes memory)
    {
        require(moduleExists[_moduleId], "NAC: Module does not exist");
        return modules[_moduleId].parameters[_paramKey];
    }

    function getModuleMetric(uint256 _moduleId, string calldata _metricKey)
        external
        view
        returns (uint256)
    {
        require(moduleExists[_moduleId], "NAC: Module does not exist");
        return modules[_moduleId].metrics[_metricKey];
    }

    function getProposalDetails(uint256 _proposalId)
        external
        view
        returns (
            uint256 id,
            ProposalType proposalType,
            uint256 targetModuleId,
            address proposer,
            uint256 startBlock,
            uint256 endBlock,
            uint256 votesFor,
            uint256 votesAgainst,
            ProposalState state,
            bytes memory dataPacked
        )
    {
        proposalExists(_proposalId);
        Proposal storage p = proposals[_proposalId];
        return (
            p.id,
            p.proposalType,
            p.targetModuleId,
            p.proposer,
            p.startBlock,
            p.endBlock,
            p.votesFor,
            p.votesAgainst,
            p.state,
            p.dataPacked
        );
    }

    function getVoterVotingPower(address _voter) external view returns (uint256) {
        return NEXUS_TOKEN.getVotes(_voter);
    }

    function getAdaptiveRuleDetails(uint256 _ruleIndex)
        external
        view
        returns (
            string memory triggerMetric,
            uint256 threshold,
            string memory targetParam,
            bytes memory newValuePacked,
            bool isAboveThreshold,
            bool isActive,
            bool hasBeenTriggered
        )
    {
        require(_ruleIndex < adaptiveRules.length, "NAC: Invalid rule index");
        AdaptiveRule storage rule = adaptiveRules[_ruleIndex];
        return (
            rule.triggerMetric,
            rule.threshold,
            rule.targetParam,
            rule.newValuePacked,
            rule.isAboveThreshold,
            rule.isActive,
            rule.hasBeenTriggered
        );
    }
}
```