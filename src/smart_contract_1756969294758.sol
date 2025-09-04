Here's a Solidity smart contract named "Chrono-Adaptive Nexus Protocol (CANP)" designed with advanced, creative, and unique functionalities, avoiding direct duplication of open-source patterns while drawing inspiration from modern blockchain concepts.

---

## Chrono-Adaptive Nexus Protocol (CANP)

This protocol represents a decentralized, self-evolving ecosystem focused on long-term resilience and dynamic adaptation. It features a sophisticated governance system, an internal reputation-based voting mechanism, modular and upgradeable logic, a dynamic treasury, and a unique system for conditional and future-oriented proposals based on internal "environmental metrics."

**Core Concepts & Innovations:**

1.  **Adaptive Module System (Self-Amending Logic):** The protocol's core logic can be dynamically amended by governance. Key functionalities (like advanced treasury strategies, reputation calculation, or environmental oracle logic) are encapsulated in "Adaptive Modules" (external contracts). Governance can vote to replace these modules, allowing the protocol to "self-amend" its capabilities without upgrading the entire main contract (assuming the core logic itself isn't drastically changed, which would require a full proxy upgrade not directly implemented here for uniqueness).
2.  **Reputation-Boosted Governance:** Voting power is not solely dependent on token holdings. A "Reputation Score" is maintained for each participant, reflecting their historical positive contributions (e.g., voting on successful proposals, submitting valid proposals). This score can amplify a user's voting power, incentivizing active and constructive participation over mere token ownership.
3.  **Conditional & Future-Oriented Proposals:** Proposals can be designed to execute only when specific, predefined on-chain "environmental metrics" are met. This allows the DAO to pre-plan reactions to market conditions, gas price fluctuations, or other internal state changes, making it more proactive and resilient.
4.  **Internal Environmental Monitor:** The protocol maintains internal "environmental metrics" (e.g., `marketSentimentIndex`, `protocolHealthIndex`). These metrics can be updated by privileged roles (or via governance proposals) and serve as triggers for conditional proposals or automatic parameter adjustments within approved bounds.
5.  **Dynamic Treasury Strategies:** The DAO can approve and execute various treasury strategies (defined in `TreasuryStrategyModule`) to manage its asset reserves, e.g., rebalancing, deploying funds to white-listed yield farms, or liquidity provision, all based on governance and environmental metrics.

---

### Outline:

**I. Core Protocol Management:**
    *   Initialization, parameter configuration, pausing mechanism, module management.

**II. CANP Token & Reputation System:**
    *   Internal, protocol-controlled token for governance.
    *   Reputation tracking, calculation, and its impact on voting power.

**III. Governance & Proposals:**
    *   Proposal creation (standard, parameter change, module upgrade, conditional).
    *   Voting mechanism, quorum, timelocks, execution, and cancellation.
    *   Delegation of voting power.

**IV. Treasury & Adaptive Strategies:**
    *   Asset deposits and governance-controlled withdrawals.
    *   Execution of approved, modular treasury strategies.

**V. Conditional & Event-Driven Actions:**
    *   Mechanism to check conditions for future-oriented proposals.
    *   Execution of proposals once their conditions are met.

**VI. Emergency & Access Control:**
    *   Role-based access control for administrative functions (simplified).

---

### Function Summary:

**I. Core Protocol Management (6 functions):**
1.  `constructor()`: Deploys the internal CANP token, sets initial parameters, and assigns initial roles.
2.  `updateCoreParameter(bytes32 _paramId, uint256 _newValue)`: Allows governance to modify core protocol settings (e.g., `votingPeriod`, `proposalThreshold`).
3.  `setAdaptiveModule(bytes32 _moduleId, address _newModuleAddress)`: Updates the address of a specific adaptive logic module (e.g., `REPUTATION_MODULE`, `TREASURY_STRATEGY_MODULE`). This is a key "self-amending" function.
4.  `getAdaptiveModule(bytes32 _moduleId)`: Retrieves the current address of a specific adaptive module.
5.  `pauseProtocol()`: Initiates an emergency protocol pause, halting critical operations.
6.  `unpauseProtocol()`: Resumes protocol operations after a pause.

**II. CANP Token & Reputation (5 functions):**
7.  `mintCANP(address _to, uint256 _amount)`: Protocol-only function to mint CANP tokens (e.g., for rewards or staking incentives).
8.  `burnCANP(address _from, uint256 _amount)`: Protocol-only function to burn CANP tokens (e.g., for penalties or leaving a stake).
9.  `getVotingPower(address _voter)`: Calculates a user's total voting power, combining their CANP balance and reputation score with a boost multiplier.
10. `calculateReputationScore(address _user)`: Returns a user's current reputation score, based on their successful governance interactions.
11. `updateReputationScore(address _user, int256 _change)`: Internal (or privileged `REPUTATION_MODULE` controlled) function to adjust a user's reputation.

**III. Governance & Proposals (8 functions):**
12. `propose(bytes32[] memory _targets, uint256[] memory _values, bytes[] memory _calldatas, string memory _description, ProposalType _type, bytes memory _conditionalTriggerData)`: Allows users to create new governance proposals. Supports standard actions, parameter changes, module upgrades, and conditional executions.
13. `vote(uint256 _proposalId, uint8 _support)`: Allows users to cast votes (for, against, abstain) on active proposals.
14. `queueProposal(uint256 _proposalId)`: Moves a successfully voted proposal to the timelock queue after its voting period ends and conditions (quorum, majority) are met.
15. `executeProposal(uint256 _proposalId)`: Executes a queued proposal after its timelock expires.
16. `cancelProposal(uint256 _proposalId)`: Allows the proposer or governance to cancel an active or queued proposal under specific conditions.
17. `getProposalState(uint256 _proposalId)`: Returns the current lifecycle state of a given proposal.
18. `getProposalDetails(uint256 _proposalId)`: Retrieves comprehensive information about a proposal.
19. `delegateVotingPower(address _delegatee)`: Allows users to delegate their CANP and reputation-boosted voting power to another address.

**IV. Treasury & Adaptive Strategies (3 functions):**
20. `depositAssets(address _token, uint256 _amount)`: Allows users or external contracts to deposit assets (e.g., ERC20 tokens) into the protocol treasury.
21. `withdrawAssets(address _token, address _to, uint256 _amount)`: Allows withdrawal of assets from the treasury, exclusively through an executed governance proposal.
22. `executeTreasuryStrategy(bytes memory _strategyData)`: Triggers an approved, parameterized treasury management strategy defined within the `TREASURY_STRATEGY_MODULE`.

**V. Conditional & Event-Driven Actions (2 functions):**
23. `updateEnvironmentalMetric(bytes32 _metricId, uint256 _newValue)`: Allows updating of internal 'environmental metrics' (e.g., `marketSentimentIndex`, `protocolHealthIndex`) by privileged roles or via governance.
24. `activateConditionalProposal(uint256 _proposalId)`: Attempts to execute a conditional proposal if its predefined conditions (as checked by `ENVIRONMENT_ORACLE_MODULE`) are currently met. Can be called by anyone.

---

### Chrono-Adaptive Nexus Protocol (CANP) Smart Contract

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ICANPToken
 * @dev Interface for the internal CANP token, which is a simplified ERC20-like token
 *      designed for protocol-internal governance and reward mechanisms.
 *      It intentionally lacks public transfer functions to focus on its role
 *      as a non-tradable governance utility within the CANP ecosystem.
 */
interface ICANPToken {
    event Mint(address indexed to, uint256 amount);
    event Burn(address indexed from, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}

/**
 * @title IEnvironmentOracleModule
 * @dev Interface for external contracts that provide environmental metric checks.
 *      These modules are pluggable via the Adaptive Module system.
 *      They are responsible for evaluating conditions for conditional proposals.
 */
interface IEnvironmentOracleModule {
    /**
     * @dev Checks if a specific conditional trigger is currently met.
     * @param _triggerData Arbitrary data specific to the trigger, interpreted by the module.
     * @return true if the condition is met, false otherwise.
     */
    function checkTrigger(bytes calldata _triggerData) external view returns (bool);
}

/**
 * @title IReputationModule
 * @dev Interface for an external reputation system module.
 *      This allows for pluggable reputation logic.
 */
interface IReputationModule {
    function getReputation(address _user) external view returns (uint256);
    function adjustReputation(address _user, int256 _change) external;
}

/**
 * @title ITreasuryStrategyModule
 * @dev Interface for external contracts that define and execute treasury strategies.
 */
interface ITreasuryStrategyModule {
    /**
     * @dev Executes a specific treasury strategy based on provided data.
     *      The strategy module must ensure it only operates with assets approved by the CANP protocol.
     * @param _strategyData Encoded data specifying the strategy to execute and its parameters.
     * @return bool indicating success.
     */
    function executeStrategy(bytes calldata _strategyData) external returns (bool);
}


contract ChronoAdaptiveNexusProtocol {
    // --- I. Global State & Configuration ---
    ICANPToken public immutable CANP_TOKEN;

    // Core Protocol Parameters (settable by governance)
    mapping(bytes32 => uint256) public coreParameters; // e.g., "VOTING_PERIOD", "PROPOSAL_THRESHOLD", "QUORUM_PERCENTAGE"

    // Adaptive Modules: addresses of external logic contracts
    mapping(bytes32 => address) public adaptiveModules; // e.g., "REPUTATION_MODULE", "ENVIRONMENT_ORACLE_MODULE", "TREASURY_STRATEGY_MODULE"
    bytes32 public constant REPUTATION_MODULE = keccak256("REPUTATION_MODULE");
    bytes32 public constant ENVIRONMENT_ORACLE_MODULE = keccak256("ENVIRONMENT_ORACLE_MODULE");
    bytes32 public constant TREASURY_STRATEGY_MODULE = keccak256("TREASURY_STRATEGY_MODULE");

    // Internal Environmental Metrics
    mapping(bytes32 => uint256) public environmentalMetrics; // e.g., "MARKET_SENTIMENT_INDEX", "PROTOCOL_HEALTH_INDEX", "GAS_PRICE_INDEX"

    // Pausability
    bool public paused;
    address private _admin; // Simplified admin for initial setup and emergency, governance takes over for most actions.
    mapping(address => bool) public pausers;

    // --- II. Governance State ---
    uint256 public nextProposalId;

    enum ProposalState { Pending, Active, Canceled, Defeated, Succeeded, Queued, Executed, Expired, ConditionalPending }
    enum ProposalType { StandardAction, ParameterChange, ModuleUpgrade, ConditionalExecution, TreasuryStrategy }

    struct Proposal {
        uint256 id;
        address proposer;
        bytes32[] targets; // Addresses for calls
        uint256[] values; // ETH values for calls
        bytes[] calldatas; // Calldata for calls
        string description;
        ProposalType pType;
        bytes conditionalTriggerData; // Specific data for conditional proposals, interpreted by EnvironmentOracleModule
        uint256 startBlock;
        uint256 endBlock;
        uint256 eta; // Estimated Time of Arrival for execution (after timelock)
        uint256 forVotes;
        uint256 againstVotes;
        uint256 abstainVotes;
        uint256 quorumRequired;
        bool executed;
        bool canceled;
    }
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public hasVoted; // proposalId => voter => true/false
    mapping(address => address) public delegates; // voter => delegatee

    // --- Events ---
    event ProposalCreated(uint256 id, address proposer, bytes32[] targets, uint256[] values, bytes[] calldatas, string description, ProposalType pType, bytes conditionalTriggerData);
    event VoteCast(address indexed voter, uint256 proposalId, uint8 support, uint256 votes, uint256 reputationBoost);
    event ProposalQueued(uint256 proposalId, uint256 eta);
    event ProposalExecuted(uint256 proposalId);
    event ProposalCanceled(uint256 proposalId);
    event CoreParameterUpdated(bytes32 indexed paramId, uint256 oldValue, uint256 newValue);
    event AdaptiveModuleSet(bytes32 indexed moduleId, address oldAddress, address newAddress);
    event EnvironmentalMetricUpdated(bytes32 indexed metricId, uint256 oldValue, uint256 newValue);
    event ProtocolPaused(address indexed by);
    event ProtocolUnpaused(address indexed by);
    event Delegated(address indexed delegator, address indexed delegatee);
    event AssetDeposited(address indexed token, address indexed sender, uint256 amount);
    event AssetWithdrawn(address indexed token, address indexed recipient, uint256 amount);
    event ConditionalProposalActivated(uint256 proposalId);

    // --- Modifiers ---
    modifier onlyAdmin() {
        require(msg.sender == _admin, "CANP: Not admin");
        _;
    }

    modifier onlyPauser() {
        require(pausers[msg.sender], "CANP: Not pauser");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "CANP: Protocol is paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "CANP: Protocol is not paused");
        _;
    }

    // --- Constructor ---
    constructor(
        uint256 _initialVotingPeriod, // in blocks
        uint256 _initialProposalThreshold, // minimum CANP to create proposal
        uint256 _initialQuorumPercentage, // e.g., 4% (400)
        uint256 _initialTimelockDelay, // in blocks, min delay for execution
        uint256 _reputationBoostMultiplier // e.g., 2x (200)
    ) {
        _admin = msg.sender; // Initial admin for setup
        pausers[msg.sender] = true; // Initial pauser

        // Deploy internal CANP Token
        CANP_TOKEN = new CANPToken(address(this)); // Protocol itself is the minter/burner

        // Set initial core parameters
        coreParameters[keccak256("VOTING_PERIOD")] = _initialVotingPeriod;
        coreParameters[keccak256("PROPOSAL_THRESHOLD")] = _initialProposalThreshold;
        coreParameters[keccak256("QUORUM_PERCENTAGE")] = _initialQuorumPercentage;
        coreParameters[keccak256("TIMELOCK_DELAY")] = _initialTimelockDelay;
        coreParameters[keccak256("REPUTATION_BOOST_MULTIPLIER")] = _reputationBoostMultiplier;

        nextProposalId = 1;
        paused = false;
    }

    // --- I. Core Protocol Management ---

    /**
     * @dev Allows governance to update a core protocol parameter.
     *      This is a common use case for `ProposalType.ParameterChange`.
     * @param _paramId The keccak256 hash of the parameter's name (e.g., keccak256("VOTING_PERIOD")).
     * @param _newValue The new value for the parameter.
     */
    function updateCoreParameter(bytes32 _paramId, uint256 _newValue) public whenNotPaused {
        // Only callable by an executed governance proposal or initial admin setup
        require(
            msg.sender == _admin || _isGovernanceExecution(),
            "CANP: Not authorized to update core parameter"
        );
        uint256 oldValue = coreParameters[_paramId];
        coreParameters[_paramId] = _newValue;
        emit CoreParameterUpdated(_paramId, oldValue, _newValue);
    }

    /**
     * @dev Sets the address of an adaptive module. This is a key "self-amending" function.
     *      Only callable by an executed governance proposal or initial admin setup.
     * @param _moduleId The keccak256 hash of the module's identifier (e.g., REPUTATION_MODULE).
     * @param _newModuleAddress The address of the new module contract.
     */
    function setAdaptiveModule(bytes32 _moduleId, address _newModuleAddress) public whenNotPaused {
        require(
            msg.sender == _admin || _isGovernanceExecution(),
            "CANP: Not authorized to set adaptive module"
        );
        require(_newModuleAddress != address(0), "CANP: Module address cannot be zero");
        address oldAddress = adaptiveModules[_moduleId];
        adaptiveModules[_moduleId] = _newModuleAddress;
        emit AdaptiveModuleSet(_moduleId, oldAddress, _newModuleAddress);
    }

    /**
     * @dev Retrieves the address of a specific adaptive module.
     * @param _moduleId The keccak256 hash of the module's identifier.
     * @return The address of the module contract.
     */
    function getAdaptiveModule(bytes32 _moduleId) public view returns (address) {
        return adaptiveModules[_moduleId];
    }

    /**
     * @dev Pauses the protocol. Can only be called by a pauser.
     */
    function pauseProtocol() public onlyPauser whenNotPaused {
        paused = true;
        emit ProtocolPaused(msg.sender);
    }

    /**
     * @dev Unpauses the protocol. Can only be called by a pauser.
     */
    function unpauseProtocol() public onlyPauser whenPaused {
        paused = false;
        emit ProtocolUnpaused(msg.sender);
    }

    /**
     * @dev Grants the pauser role to an address. Only callable by admin or governance.
     *      For a truly decentralized system, this would be a governance action.
     * @param _account The address to grant pauser role.
     */
    function grantPauser(address _account) public {
        require(msg.sender == _admin || _isGovernanceExecution(), "CANP: Not authorized to grant pauser");
        require(!pausers[_account], "CANP: Account already a pauser");
        pausers[_account] = true;
    }

    /**
     * @dev Revokes the pauser role from an address. Only callable by admin or governance.
     * @param _account The address to revoke pauser role from.
     */
    function revokePauser(address _account) public {
        require(msg.sender == _admin || _isGovernanceExecution(), "CANP: Not authorized to revoke pauser");
        require(pausers[_account], "CANP: Account not a pauser");
        pausers[_account] = false;
    }

    /**
     * @dev Allows an existing pauser to renounce their pauser role.
     */
    function renouncePauser() public pausers[msg.sender] {
        pausers[msg.sender] = false;
    }

    // --- II. CANP Token & Reputation ---

    /**
     * @dev Protocol-only function to mint CANP tokens.
     *      Used for rewarding participants, staking incentives, etc.
     * @param _to The recipient of the tokens.
     * @param _amount The amount of tokens to mint.
     */
    function mintCANP(address _to, uint256 _amount) public whenNotPaused {
        require(_isGovernanceExecution(), "CANP: Only callable by executed governance proposal");
        CANP_TOKEN.mint(_to, _amount);
        // Optionally update reputation here based on minting context
        _updateReputationScore(_to, int256(_amount / 1e18)); // Example: 1 reputation per 1 CANP (simplified)
    }

    /**
     * @dev Protocol-only function to burn CANP tokens.
     *      Used for penalties, unstaking with fees, or other governance-approved mechanisms.
     * @param _from The account from which tokens are burned.
     * @param _amount The amount of tokens to burn.
     */
    function burnCANP(address _from, uint256 _amount) public whenNotPaused {
        require(_isGovernanceExecution(), "CANP: Only callable by executed governance proposal");
        CANP_TOKEN.burn(_from, _amount);
        // Optionally update reputation here based on burning context (e.g., penalty)
        _updateReputationScore(_from, -int256(_amount / 1e18)); // Example: lose 1 reputation per 1 CANP burned
    }

    /**
     * @dev Calculates a user's total voting power, combining CANP balance and a reputation-based boost.
     * @param _voter The address of the voter.
     * @return The total effective voting power.
     */
    function getVotingPower(address _voter) public view returns (uint256) {
        uint256 canpBalance = CANP_TOKEN.balanceOf(_voter);
        uint256 reputationScore = calculateReputationScore(_voter);
        uint256 reputationBoost = (reputationScore * coreParameters[keccak256("REPUTATION_BOOST_MULTIPLIER")]) / 100; // Multiplier is /100
        return canpBalance + reputationBoost;
    }

    /**
     * @dev Retrieves a user's current reputation score.
     * @param _user The address of the user.
     * @return The user's reputation score.
     */
    function calculateReputationScore(address _user) public view returns (uint256) {
        address reputationModuleAddress = adaptiveModules[REPUTATION_MODULE];
        if (reputationModuleAddress == address(0)) {
            // Fallback or default reputation if no module is set
            return 0; // or some initial value
        }
        return IReputationModule(reputationModuleAddress).getReputation(_user);
    }

    /**
     * @dev Internal (or module-controlled) function to adjust a user's reputation score.
     *      This would typically be called by the protocol after certain events (e.g., successful proposal vote).
     * @param _user The address of the user whose reputation is being updated.
     * @param _change The amount to add or subtract from the reputation score (can be negative).
     */
    function _updateReputationScore(address _user, int256 _change) internal {
        address reputationModuleAddress = adaptiveModules[REPUTATION_MODULE];
        if (reputationModuleAddress == address(0)) {
            // Handle without module, or simply return if reputation system is not active
            return;
        }
        IReputationModule(reputationModuleAddress).adjustReputation(_user, _change);
    }

    // --- III. Governance & Proposals ---

    /**
     * @dev Creates a new governance proposal.
     * @param _targets The target addresses for the proposal's actions.
     * @param _values The ETH values to send with each action.
     * @param _calldatas The encoded function calls for each action.
     * @param _description A detailed description of the proposal.
     * @param _type The type of proposal (StandardAction, ParameterChange, ModuleUpgrade, ConditionalExecution, TreasuryStrategy).
     * @param _conditionalTriggerData Specific data for ConditionalExecution proposals, interpreted by EnvironmentOracleModule.
     *        For other types, this can be empty bytes.
     * @return The ID of the newly created proposal.
     */
    function propose(
        bytes32[] memory _targets,
        uint256[] memory _values,
        bytes[] memory _calldatas,
        string memory _description,
        ProposalType _type,
        bytes memory _conditionalTriggerData
    ) public whenNotPaused returns (uint256) {
        require(_targets.length == _values.length && _targets.length == _calldatas.length, "CANP: Mismatched array lengths");
        require(_targets.length > 0, "CANP: Must propose at least one action");
        require(bytes(_description).length > 0, "CANP: Proposal description cannot be empty");
        require(getVotingPower(msg.sender) >= coreParameters[keccak256("PROPOSAL_THRESHOLD")], "CANP: Not enough voting power to propose");

        uint256 proposalId = nextProposalId++;
        uint256 votingPeriod = coreParameters[keccak256("VOTING_PERIOD")];
        uint256 quorumPercentage = coreParameters[keccak256("QUORUM_PERCENTAGE")];

        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            targets: _targets,
            values: _values,
            calldatas: _calldatas,
            description: _description,
            pType: _type,
            conditionalTriggerData: _conditionalTriggerData,
            startBlock: block.number,
            endBlock: block.number + votingPeriod,
            eta: 0, // Set when queued
            forVotes: 0,
            againstVotes: 0,
            abstainVotes: 0,
            quorumRequired: (CANP_TOKEN.balanceOf(address(this)) * quorumPercentage) / 10000, // Quorum based on total CANP in protocol (or total supply)
            executed: false,
            canceled: false
        });

        emit ProposalCreated(proposalId, msg.sender, _targets, _values, _calldatas, _description, _type, _conditionalTriggerData);
        return proposalId;
    }

    /**
     * @dev Casts a vote on an active proposal.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support The vote (0: Against, 1: For, 2: Abstain).
     */
    function vote(uint256 _proposalId, uint8 _support) public whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "CANP: Proposal does not exist");
        require(getProposalState(_proposalId) == ProposalState.Active, "CANP: Proposal not active");
        require(!hasVoted[_proposalId][msg.sender], "CANP: Already voted on this proposal");
        require(_support <= 2, "CANP: Invalid vote support value");

        address voter = delegates[msg.sender] != address(0) ? delegates[msg.sender] : msg.sender;
        uint256 voterPower = getVotingPower(voter);
        require(voterPower > 0, "CANP: Voter has no voting power");

        hasVoted[_proposalId][voter] = true;

        if (_support == 0) {
            proposal.againstVotes += voterPower;
        } else if (_support == 1) {
            proposal.forVotes += voterPower;
        } else {
            proposal.abstainVotes += voterPower;
        }
        emit VoteCast(voter, _proposalId, _support, voterPower, calculateReputationScore(voter));
    }

    /**
     * @dev Moves a successfully voted proposal to the timelock queue.
     *      Can be called by anyone after the voting period ends and criteria are met.
     * @param _proposalId The ID of the proposal to queue.
     */
    function queueProposal(uint256 _proposalId) public whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "CANP: Proposal does not exist");
        require(getProposalState(_proposalId) == ProposalState.Succeeded, "CANP: Proposal not succeeded");
        require(proposal.eta == 0, "CANP: Proposal already queued");

        uint256 timelockDelay = coreParameters[keccak256("TIMELOCK_DELAY")];
        proposal.eta = block.timestamp + timelockDelay; // Using timestamp for timelock

        emit ProposalQueued(_proposalId, proposal.eta);
    }

    /**
     * @dev Executes a queued proposal after its timelock expires.
     *      Can be called by anyone.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) public payable whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "CANP: Proposal does not exist");
        require(getProposalState(_proposalId) == ProposalState.Queued, "CANP: Proposal not queued or conditions not met");
        require(block.timestamp >= proposal.eta, "CANP: Timelock has not expired");

        proposal.executed = true;

        // Perform actions
        for (uint256 i = 0; i < proposal.targets.length; i++) {
            address target = proposal.targets[i];
            uint256 value = proposal.values[i];
            bytes memory calldataPayload = proposal.calldatas[i];

            (bool success, bytes memory result) = target.call{value: value}(calldataPayload);
            require(success, string(abi.encodePacked("CANP: Action failed for target ", _toAsciiString(target), ": ", result)));
        }

        // Update reputation for voters who supported successful proposal
        // This would require iterating through all votes, which is gas intensive.
        // A more practical approach would be for the Reputation Module to track this off-chain
        // or for this contract to store only a hash of winning voters and allow them to claim reputation points.
        // For this example, we'll keep the update simple but acknowledge the limitation.
        _updateReputationScore(proposal.proposer, 5); // Example reward for successful proposer

        emit ProposalExecuted(_proposalId);
    }


    /**
     * @dev Cancels an active or queued proposal.
     *      Can be called by the proposer (if not yet queued) or by governance (if fraud detected).
     * @param _proposalId The ID of the proposal to cancel.
     */
    function cancelProposal(uint256 _proposalId) public whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "CANP: Proposal does not exist");
        require(getProposalState(_proposalId) < ProposalState.Succeeded, "CANP: Cannot cancel succeeded or executed proposal");
        require(!proposal.canceled, "CANP: Proposal already canceled");
        require(
            msg.sender == proposal.proposer || _isGovernanceExecution(), // Only proposer or governance can cancel
            "CANP: Not authorized to cancel proposal"
        );

        proposal.canceled = true;
        emit ProposalCanceled(_proposalId);
    }

    /**
     * @dev Returns the current state of a given proposal.
     * @param _proposalId The ID of the proposal.
     * @return The current state (Pending, Active, Canceled, Defeated, Succeeded, Queued, Executed, Expired).
     */
    function getProposalState(uint256 _proposalId) public view returns (ProposalState) {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) return ProposalState.Pending; // Non-existent proposal implicitly pending
        if (proposal.canceled) return ProposalState.Canceled;
        if (proposal.executed) return ProposalState.Executed;

        if (block.number <= proposal.startBlock) return ProposalState.Pending;
        if (block.number <= proposal.endBlock) return ProposalState.Active;

        // Voting period has ended
        uint256 totalVotes = proposal.forVotes + proposal.againstVotes + proposal.abstainVotes;
        if (totalVotes < proposal.quorumRequired) return ProposalState.Defeated;
        if (proposal.forVotes <= proposal.againstVotes) return ProposalState.Defeated;

        // If it's a ConditionalExecution type, it moves to ConditionalPending instead of Succeeded immediately
        if (proposal.pType == ProposalType.ConditionalExecution) {
            if (proposal.eta != 0) return ProposalState.Queued; // If it somehow got queued, it is queued
            return ProposalState.ConditionalPending;
        }

        // Standard Succeeded state
        if (proposal.eta != 0) {
            if (block.timestamp < proposal.eta) return ProposalState.Queued;
            return ProposalState.Expired; // Timelock expired, but not executed
        }
        return ProposalState.Succeeded;
    }

    /**
     * @dev Retrieves comprehensive details about a proposal.
     * @param _proposalId The ID of the proposal.
     * @return A tuple containing all proposal details.
     */
    function getProposalDetails(uint256 _proposalId) public view returns (
        uint256 id,
        address proposer,
        bytes32[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description,
        ProposalType pType,
        bytes memory conditionalTriggerData,
        uint256 startBlock,
        uint256 endBlock,
        uint256 eta,
        uint256 forVotes,
        uint256 againstVotes,
        uint256 abstainVotes,
        uint256 quorumRequired,
        bool executed,
        bool canceled
    ) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "CANP: Proposal does not exist");
        return (
            proposal.id,
            proposal.proposer,
            proposal.targets,
            proposal.values,
            proposal.calldatas,
            proposal.description,
            proposal.pType,
            proposal.conditionalTriggerData,
            proposal.startBlock,
            proposal.endBlock,
            proposal.eta,
            proposal.forVotes,
            proposal.againstVotes,
            proposal.abstainVotes,
            proposal.quorumRequired,
            proposal.executed,
            proposal.canceled
        );
    }

    /**
     * @dev Allows a user to delegate their voting power to another address.
     * @param _delegatee The address to delegate voting power to.
     */
    function delegateVotingPower(address _delegatee) public whenNotPaused {
        require(_delegatee != address(0), "CANP: Delegatee cannot be zero address");
        require(_delegatee != msg.sender, "CANP: Cannot delegate to self");
        delegates[msg.sender] = _delegatee;
        emit Delegated(msg.sender, _delegatee);
    }

    // --- IV. Treasury & Adaptive Strategies ---

    /**
     * @dev Allows users or external contracts to deposit assets into the protocol treasury.
     * @param _token The address of the ERC20 token to deposit (address(0) for ETH).
     * @param _amount The amount of tokens/ETH to deposit.
     */
    function depositAssets(address _token, uint256 _amount) public payable whenNotPaused {
        if (_token == address(0)) { // ETH deposit
            require(msg.value == _amount, "CANP: ETH amount mismatch");
        } else { // ERC20 token deposit
            require(msg.value == 0, "CANP: Cannot send ETH with ERC20 deposit");
            // Approve protocol to pull tokens first
            require(
                IERC20(_token).transferFrom(msg.sender, address(this), _amount),
                "CANP: ERC20 transfer failed"
            );
        }
        emit AssetDeposited(_token, msg.sender, _amount);
    }

    /**
     * @dev Allows withdrawal of assets from the treasury. Only via executed governance proposals.
     * @param _token The address of the ERC20 token to withdraw (address(0) for ETH).
     * @param _to The recipient of the assets.
     * @param _amount The amount to withdraw.
     */
    function withdrawAssets(address _token, address _to, uint256 _amount) public whenNotPaused {
        require(_isGovernanceExecution(), "CANP: Only callable by executed governance proposal");
        require(_to != address(0), "CANP: Recipient cannot be zero address");

        if (_token == address(0)) { // ETH withdrawal
            (bool success, ) = _to.call{value: _amount}("");
            require(success, "CANP: ETH transfer failed");
        } else { // ERC20 token withdrawal
            require(IERC20(_token).transfer(_to, _amount), "CANP: ERC20 transfer failed");
        }
        emit AssetWithdrawn(_token, _to, _amount);
    }

    /**
     * @dev Triggers an approved, parameterized treasury management strategy.
     *      Only callable by an executed governance proposal (ProposalType.TreasuryStrategy).
     * @param _strategyData Encoded data specific to the strategy, interpreted by the TreasuryStrategyModule.
     */
    function executeTreasuryStrategy(bytes memory _strategyData) public whenNotPaused {
        require(_isGovernanceExecution(), "CANP: Only callable by executed governance proposal");
        address treasuryStrategyModuleAddress = adaptiveModules[TREASURY_STRATEGY_MODULE];
        require(treasuryStrategyModuleAddress != address(0), "CANP: Treasury Strategy Module not set");
        ITreasuryStrategyModule(treasuryStrategyModuleAddress).executeStrategy(_strategyData);
    }

    // --- V. Conditional & Event-Driven Actions ---

    /**
     * @dev Allows privileged roles or governance to update internal 'environmental metrics'.
     *      These metrics can be used to trigger conditional proposals.
     * @param _metricId The keccak256 hash of the metric's identifier (e.g., keccak256("MARKET_SENTIMENT_INDEX")).
     * @param _newValue The new value for the metric.
     */
    function updateEnvironmentalMetric(bytes32 _metricId, uint256 _newValue) public whenNotPaused {
        // Can be restricted to a specific oracle role or governed by proposals
        require(msg.sender == _admin || _isGovernanceExecution(), "CANP: Not authorized to update environmental metric");
        uint256 oldValue = environmentalMetrics[_metricId];
        environmentalMetrics[_metricId] = _newValue;
        emit EnvironmentalMetricUpdated(_metricId, oldValue, _newValue);
    }

    /**
     * @dev Attempts to execute a conditional proposal if its predefined conditions are met.
     *      Can be called by anyone, incentivizing external agents to monitor and trigger.
     * @param _proposalId The ID of the conditional proposal.
     */
    function activateConditionalProposal(uint256 _proposalId) public payable whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "CANP: Proposal does not exist");
        require(getProposalState(_proposalId) == ProposalState.ConditionalPending, "CANP: Proposal not in ConditionalPending state");
        require(proposal.pType == ProposalType.ConditionalExecution, "CANP: Proposal is not a conditional execution type");

        address envOracleModuleAddress = adaptiveModules[ENVIRONMENT_ORACLE_MODULE];
        require(envOracleModuleAddress != address(0), "CANP: Environment Oracle Module not set");
        require(IEnvironmentOracleModule(envOracleModuleAddress).checkTrigger(proposal.conditionalTriggerData), "CANP: Conditional trigger not met");

        // If conditions are met, queue it for immediate execution (or after a minimal delay)
        // For simplicity, we'll directly execute if all other checks pass, bypassing a timelock for time-sensitive conditional triggers.
        // A more robust system might still queue it with a very short ETA.
        proposal.executed = true;

        for (uint252 i = 0; i < proposal.targets.length; i++) {
            address target = proposal.targets[i];
            uint252 value = proposal.values[i];
            bytes memory calldataPayload = proposal.calldatas[i];

            (bool success, bytes memory result) = target.call{value: value}(calldataPayload);
            require(success, string(abi.encodePacked("CANP: Conditional action failed for target ", _toAsciiString(target), ": ", result)));
        }

        emit ConditionalProposalActivated(_proposalId);
    }

    // --- Internal Helpers ---

    /**
     * @dev Checks if the current call is being made by an executed governance proposal.
     *      This pattern allows governance to call "internal" functions.
     */
    function _isGovernanceExecution() internal view returns (bool) {
        // This is a simplified check. A full implementation would involve
        // checking the `msg.sender` against a specific, internal governance execution role
        // or a proxy system. For this example, we assume only the _admin can trigger it directly,
        // otherwise it MUST be an executed proposal.
        // As proposals execute directly by calling target functions, the msg.sender of those
        // target functions will be THIS contract's address.
        // This might need refinement depending on the exact proxy/execution architecture.
        // For this specific example, let's allow _admin for setup, and then rely on the target.call
        // within executeProposal(). The functions called by executeProposal() will have this contract's
        // address as msg.sender.
        return msg.sender == address(this);
    }

    /**
     * @dev Converts an address to an ASCII string for error messages.
     */
    function _toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(x) / (1**(38 - i * 2))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[i * 2] = _toAsciiChar(hi);
            s[i * 2 + 1] = _toAsciiChar(lo);
        }
        return string(s);
    }

    /**
     * @dev Converts a hex digit to its ASCII character.
     */
    function _toAsciiChar(bytes1 b) internal pure returns (bytes1) {
        if (b < 0xA) return bytes1(uint8(b) + 0x30);
        return bytes1(uint8(b) + 0x57);
    }

    // Fallback function to receive ETH into the treasury
    receive() external payable whenNotPaused {
        emit AssetDeposited(address(0), msg.sender, msg.value);
    }
}

/**
 * @title CANPToken
 * @dev A simplified internal token for the Chrono-Adaptive Nexus Protocol.
 *      It functions as an ERC20-like token but specifically for internal protocol use,
 *      primarily for governance voting power and rewards.
 *      It does NOT have public transfer functions to emphasize its non-tradable nature
 *      and focus on its utility within the CANP ecosystem.
 *      The protocol itself is the sole minter and burner.
 */
contract CANPToken is ICANPToken {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    address public immutable PROTOCOL_CONTRACT;

    string public constant name = "Chrono-Adaptive Nexus Protocol Token";
    string public constant symbol = "CANP";
    uint8 public constant decimals = 18;
    uint256 private _totalSupply;

    constructor(address _protocolContract) {
        PROTOCOL_CONTRACT = _protocolContract;
    }

    modifier onlyProtocol() {
        require(msg.sender == PROTOCOL_CONTRACT, "CANPToken: Only protocol can call");
        _;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    // No public transfer/transferFrom to prevent free trading.
    // If a trading mechanism is desired, it would be integrated via a separate governance-approved module.

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "CANPToken: approve from the zero address");
        require(spender != address(0), "CANPToken: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function mint(address to, uint256 amount) public override onlyProtocol {
        require(to != address(0), "CANPToken: mint to the zero address");
        _totalSupply += amount;
        _balances[to] += amount;
        emit Mint(to, amount);
    }

    function burn(address from, uint256 amount) public override onlyProtocol {
        require(from != address(0), "CANPToken: burn from the zero address");
        require(_balances[from] >= amount, "CANPToken: burn amount exceeds balance");
        _totalSupply -= amount;
        _balances[from] -= amount;
        emit Burn(from, amount);
    }
}

// Example Mock Modules (for demonstration purposes)
// In a real deployment, these would be separate, more complex contracts.

contract MockReputationModule is IReputationModule {
    mapping(address => uint256) private _reputationScores;

    function getReputation(address _user) external view override returns (uint256) {
        return _reputationScores[_user];
    }

    function adjustReputation(address _user, int256 _change) external override {
        // Simple adjustment, real logic would be more complex (e.g., decay, max cap)
        if (_change > 0) {
            _reputationScores[_user] += uint256(_change);
        } else {
            if (_reputationScores[_user] < uint256(-_change)) {
                _reputationScores[_user] = 0;
            } else {
                _reputationScores[_user] -= uint256(-_change);
            }
        }
    }
}

contract MockEnvironmentOracleModule is IEnvironmentOracleModule {
    // Example: This module might track a "market volatility index"
    mapping(bytes32 => uint256) public trackedMetrics;

    // Simulate an external update function (in a real scenario, this would be an oracle)
    function setMetric(bytes32 _metricId, uint256 _value) public {
        trackedMetrics[_metricId] = _value;
    }

    // Example condition check: Is market sentiment above a threshold?
    function checkTrigger(bytes calldata _triggerData) external view override returns (bool) {
        // _triggerData could encode:
        // bytes32 metricId;
        // uint256 threshold;
        // uint8 comparisonType (e.g., 0 for >, 1 for <)
        (bytes32 metricId, uint256 threshold, uint8 comparisonType) = abi.decode(_triggerData, (bytes32, uint256, uint8));

        if (comparisonType == 0) { // Greater than
            return trackedMetrics[metricId] > threshold;
        } else if (comparisonType == 1) { // Less than
            return trackedMetrics[metricId] < threshold;
        }
        return false;
    }
}

contract MockTreasuryStrategyModule is ITreasuryStrategyModule {
    // In a real scenario, this would hold complex DeFi interactions.
    // For this mock, it simply logs the strategy attempt.
    event StrategyExecuted(bytes indexed strategyData);

    function executeStrategy(bytes calldata _strategyData) external override returns (bool) {
        // Example: The strategyData could specify rebalancing tokens, depositing to a yield farm.
        // E.g., abi.encode(tokenA, tokenB, rebalanceRatio, targetProtocolAddress)
        emit StrategyExecuted(_strategyData);
        return true;
    }
}

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}
```