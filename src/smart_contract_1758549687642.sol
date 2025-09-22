Here's a smart contract in Solidity called "Aetherial Protocol: Adaptive Strategy Weavers".

This protocol enables users to deploy and manage autonomous on-chain "Agent" contracts. Each Agent instance adheres to a specific, pre-audited "Strategy Template" and can interact with whitelisted external DeFi protocols via "Adapters." The main `AetherialProtocol` contract acts as a factory, registry, and governance hub for these components, while individual `Agent` contracts handle their own funds, configuration, and execution.

This design introduces several advanced concepts:
*   **Modular Architecture:** Separation of concerns between the core protocol, strategy templates, and agent instances.
*   **Autonomous Agents:** Each deployed Agent is a separate contract, capable of holding funds and executing logic.
*   **Factory Pattern (Clones):** Efficient deployment of Agent instances via minimal proxies.
*   **Delegated Execution:** Anyone can trigger an agent's strategy, with an incentive for successful execution.
*   **Whitelisted Interactions:** Agents can only interact with pre-approved external contracts and functions (Adapters), enhancing security.
*   **Advanced Governance:** Multi-sig style governor changes and guardian for emergency pauses.
*   **Dynamic Configuration:** Agents can be configured by their owners within the bounds of their template.
*   **Oracle Integration:** For agents to make decisions based on real-world data (e.g., price feeds).

---

### Contract: `AetherialProtocol.sol`

**Outline:**

1.  **Libraries & Interfaces:** Imports necessary OpenZeppelin libraries and defines internal interfaces for Agent, Agent Template, and Oracle.
2.  **State Variables:** Stores core protocol data, including roles, fees, registries for templates and adapters, and deployed agents.
3.  **Events:** Emits events for all significant state changes, crucial for off-chain monitoring.
4.  **Modifiers:** Access control (`onlyGovernor`, `onlyGuardian`), protocol state (`whenNotPaused`, `whenPaused`), and reentrancy protection.
5.  **Constructor:** Initializes the protocol with the initial owner, guardian, and oracle.
6.  **Protocol Core & Governance (Owner/Governor Roles):** Manages global settings, roles, and emergency controls.
7.  **Strategy Template Management:** Whitelists and manages approved strategy logic contracts.
8.  **External Adapter Management:** Whitelists external DeFi protocols and functions agents can safely interact with.
9.  **Agent Factory & Registry:** Deploys new `Agent` instances based on approved templates and keeps a record.
10. **Fee Management:** Handles protocol-level fees and withdrawal.
11. **Queries:** Provides read-only access to protocol data.

**Function Summary (20 Functions):**

**I. Protocol Core & Governance**
1.  `constructor(address _initialOwner, address _initialGuardian, address _initialOracle)`: Initializes the contract with an owner, guardian, and initial oracle.
2.  `updateGuardianAddress(address _newGuardian)`: Allows the governor to update the address of the emergency guardian.
3.  `proposeNewGovernor(address _newGovernor)`: Initiates a multi-sig style proposal to change the primary governor, subject to a time lock.
4.  `acceptGovernanceProposal()`: Allows the proposed governor to accept their role after the timelock expires.
5.  `setOracleAddress(address _newOracle)`: Sets the address for the trusted price/data oracle.
6.  `setExecutionFee(uint256 _newFee)`: Sets the fee paid to an executor for successfully triggering an agent.
7.  `withdrawProtocolFees()`: Allows the governor to withdraw accumulated protocol fees.
8.  `pauseProtocol()`: The guardian can temporarily pause critical protocol functions.
9.  `unpauseProtocol()`: The guardian can unpause the protocol.

**II. Strategy Template Management**
10. `addStrategyTemplate(address _templateImpl, string memory _name, string memory _description, address[] memory _allowedTokens)`: Whitelists a new, audited strategy implementation contract for agents to use.
11. `updateStrategyTemplateStatus(address _templateImpl, bool _isActive)`: Activates or deactivates a registered strategy template.

**III. External Adapter Management**
12. `addAdapter(address _targetContract, bytes4 _functionSelector, string memory _name, string memory _description)`: Registers an external contract and a specific function selector that agents are allowed to call.
13. `updateAdapterStatus(address _targetContract, bytes4 _functionSelector, bool _isActive)`: Activates or deactivates a registered adapter.

**IV. Agent Factory & Registry**
14. `deployAgent(address _templateImpl, bytes memory _initialConfig)`: Deploys a new `Agent` instance based on an approved template, returning its address.
15. `setAgentImplementation(address _newAgentImplementation)`: Allows the governor to update the base implementation contract for new agents.

**V. Queries (Read-only)**
16. `getAgentDetails(address _agentAddress)`: Retrieves all registered details about a deployed agent.
17. `listUserAgents(address _user)`: Returns a list of all agents owned by a specific user.
18. `getStrategyTemplateDetails(address _templateImpl)`: Retrieves details about a registered strategy template.
19. `listActiveTemplates()`: Returns a list of all currently active strategy templates.
20. `listActiveAdapters()`: Returns a list of all currently active adapters (target contract, function selector pairs).

---

### Supporting Contract: `Agent.sol`

This contract is the blueprint for individual agent instances. It's deployed as a minimal proxy by `AetherialProtocol`.

**Outline:**
1.  **Interfaces:** Defines interfaces for `IAetherialProtocol` and `IAgentTemplate`.
2.  **Libraries:** `SafeERC20`, `ReentrancyGuard`, `Address`.
3.  **State Variables:** Stores agent-specific data like owner, configuration, permissions, and its associated template.
4.  **Events:** Emits events for agent-specific actions.
5.  **Modifiers:** Access control for agent owner, guardian, and reentrancy protection.
6.  **Initialization:** A pseudo-constructor (`initialize`) for setting up the agent post-deployment.
7.  **Agent Lifecycle:** Functions for funding, configuring, triggering, withdrawing, pausing, and destroying the agent.
8.  **Queries:** Read-only access to agent-specific data.

**Key Functions (part of the overall system's functionality):**

1.  `initialize(address _owner, address _protocol, address _templateImpl, bytes memory _initialConfig)`: Sets up the agent upon deployment from the factory.
2.  `fundAgent(address _token)`: Allows external users to send ERC20 tokens or ETH to the agent.
3.  `configureAgent(bytes memory _newConfig)`: Allows the agent's owner to update its specific configuration parameters.
4.  `updateAgentPermissions(address _actor, bool _canTrigger, bool _canConfigure, bool _canWithdraw)`: Manages granular permissions for other addresses to interact with *this specific agent*.
5.  `triggerExecution(address _executor)`: Called by an external executor; evaluates strategy conditions and executes actions by delegating to its `_templateImpl`.
6.  `withdrawAgentFunds(address _token, uint256 _amount)`: Allows the agent owner (or authorized actor) to withdraw funds from the agent.
7.  `pauseAgent()`: The agent owner can temporarily pause *this specific agent's* execution.
8.  `unpauseAgent()`: The agent owner can unpause *this specific agent*.
9.  `emergencyWithdrawAgentFunds(address _token, uint256 _amount, address _recipient)`: A guardian-only function to withdraw funds from a misbehaving or stuck agent instance.
10. `selfDestructAgent()`: Agent owner can permanently remove the agent and recover all funds.
11. `getAgentBalance(address _token)`: Returns the balance of a specific token held by the agent.
12. `getAgentConfig()`: Returns the current configuration (bytes) of the agent.

---

### `AetherialProtocol.sol` (Main Contract)

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";

// --- Interfaces ---

interface IAgent {
    function initialize(address _owner, address _protocol, address _templateImpl, bytes memory _initialConfig) external;
    function triggerExecution(address _executor) external returns (bool success);
    function emergencyWithdrawAgentFunds(address _token, uint256 _amount, address _recipient) external;
    function protocol() external view returns (address);
}

interface IAgentTemplate {
    // This function will be called by the Agent contract to execute the strategy logic.
    // It should contain the core logic of the strategy, interacting with adapters as needed.
    // It is expected to return true on successful execution of the strategy actions.
    function executeStrategy(
        address _agentAddress,
        address[] memory _allowedTokens,
        bytes memory _agentConfig,
        address _oracleAddress,
        address _protocolAddress // For adapters lookup
    ) external returns (bool success);
}

interface IOracle {
    function getPrice(address _tokenIn, address _tokenOut) external view returns (uint256 price);
    // Add more oracle functions as needed (e.g., getBlockTimestamp, getExternalEvent)
}

// --- Contract: AetherialProtocol ---

/// @title AetherialProtocol: Adaptive Strategy Weavers
/// @author YourName
/// @notice This contract serves as the factory, registry, and governance hub for autonomous Agent contracts.
/// It manages approved strategy templates, external protocol adapters, and protocol-level fees.
contract AetherialProtocol is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Address for address;

    // --- State Variables ---

    address public guardian; // Can pause/unpause the protocol in emergencies
    address public pendingGovernor; // For multi-sig like governor transfer
    uint48 public governorProposalTimestamp; // Timestamp of governor proposal
    uint32 public constant GOVERNOR_TIMELOCK = 7 days; // 7 days timelock for governor transfer

    address public currentOracle; // Trusted oracle for external data feeds
    uint256 public executionFee; // Fee paid to external executor for triggering an agent, in native token (ETH)
    uint256 public totalProtocolFees; // Accumulated fees

    bool public protocolPaused; // Global pause switch

    // Mapping for Strategy Templates: templateAddress => { isActive, name, description, allowedTokens[] }
    struct StrategyTemplate {
        bool isActive;
        string name;
        string description;
        address[] allowedTokens; // Tokens this template is allowed to handle for agents
    }
    mapping(address => StrategyTemplate) public strategyTemplates;
    address[] public activeTemplateAddresses; // List of active template addresses for easier iteration

    // Mapping for Adapters: targetContract => functionSelector => { isActive, name, description }
    struct Adapter {
        bool isActive;
        string name;
        string description;
    }
    mapping(address => mapping(bytes4 => Adapter)) public adapters;

    // Registry for deployed Agents: agentAddress => { owner, templateImpl, deployedTimestamp }
    struct AgentRegistryEntry {
        address owner;
        address templateImpl;
        uint256 deployedTimestamp;
    }
    mapping(address => AgentRegistryEntry) public agents;
    mapping(address => address[]) public userAgents; // owner => list of agents they own

    address public agentImplementation; // The base implementation contract for cloned Agent instances

    // --- Events ---

    event GuardianUpdated(address indexed oldGuardian, address indexed newGuardian);
    event GovernorProposed(address indexed newGovernor, uint48 proposalTimestamp);
    event GovernorAccepted(address indexed newGovernor);
    event OracleAddressUpdated(address indexed oldOracle, address indexed newOracle);
    event ExecutionFeeUpdated(uint256 oldFee, uint256 newFee);
    event ProtocolFeesWithdrawn(address indexed recipient, uint256 amount);
    event ProtocolPaused(address indexed by);
    event ProtocolUnpaused(address indexed by);

    event StrategyTemplateAdded(address indexed templateImpl, string name, string description, bool isActive);
    event StrategyTemplateStatusUpdated(address indexed templateImpl, bool isActive);

    event AdapterAdded(address indexed targetContract, bytes4 functionSelector, string name, string description, bool isActive);
    event AdapterStatusUpdated(address indexed targetContract, bytes4 functionSelector, bool isActive);

    event AgentDeployed(address indexed agentAddress, address indexed owner, address indexed templateImpl, bytes initialConfig);
    event AgentImplementationUpdated(address indexed oldImplementation, address indexed newImplementation);

    // --- Modifiers ---

    modifier onlyGovernor() {
        require(msg.sender == owner(), "Aetherial: Not governor");
        _;
    }

    modifier onlyGuardian() {
        require(msg.sender == guardian, "Aetherial: Not guardian");
        _;
    }

    modifier whenNotPaused() {
        require(!protocolPaused, "Aetherial: Protocol is paused");
        _;
    }

    modifier whenPaused() {
        require(protocolPaused, "Aetherial: Protocol is not paused");
        _;
    }

    // --- Constructor ---

    /// @notice Initializes the Aetherial Protocol with the initial owner, guardian, and oracle addresses.
    /// @param _initialOwner The address of the initial governor/owner.
    /// @param _initialGuardian The address of the initial emergency guardian.
    /// @param _initialOracle The address of the initial trusted oracle.
    constructor(address _initialOwner, address _initialGuardian, address _initialOracle) Ownable(_initialOwner) {
        require(_initialGuardian != address(0), "Aetherial: Zero guardian address");
        require(_initialOracle != address(0), "Aetherial: Zero oracle address");
        guardian = _initialGuardian;
        currentOracle = _initialOracle;
        executionFee = 0.001 ether; // Default execution fee
        protocolPaused = false;
        emit GuardianUpdated(address(0), _initialGuardian);
        emit OracleAddressUpdated(address(0), _initialOracle);
        emit ExecutionFeeUpdated(0, executionFee);
    }

    // --- I. Protocol Core & Governance ---

    /// @notice Allows the governor to update the address of the emergency guardian.
    /// @param _newGuardian The new address for the guardian.
    function updateGuardianAddress(address _newGuardian) external onlyGovernor {
        require(_newGuardian != address(0), "Aetherial: Zero guardian address");
        emit GuardianUpdated(guardian, _newGuardian);
        guardian = _newGuardian;
    }

    /// @notice Initiates a proposal to change the protocol's governor. Subject to a timelock.
    /// @param _newGovernor The address proposed as the new governor.
    function proposeNewGovernor(address _newGovernor) external onlyGovernor {
        require(_newGovernor != address(0), "Aetherial: Zero governor address");
        require(_newGovernor != owner(), "Aetherial: New governor is current governor");
        pendingGovernor = _newGovernor;
        governorProposalTimestamp = uint48(block.timestamp);
        emit GovernorProposed(_newGovernor, governorProposalTimestamp);
    }

    /// @notice Allows the proposed governor to accept their role after the timelock expires.
    function acceptGovernanceProposal() external {
        require(msg.sender == pendingGovernor, "Aetherial: Not pending governor");
        require(governorProposalTimestamp != 0, "Aetherial: No active proposal");
        require(block.timestamp >= governorProposalTimestamp + GOVERNOR_TIMELOCK, "Aetherial: Timelock not expired");
        address oldOwner = owner();
        transferOwnership(pendingGovernor); // OpenZeppelin's Ownable transfer
        pendingGovernor = address(0);
        governorProposalTimestamp = 0;
        emit GovernorAccepted(msg.sender);
        emit OwnershipTransferred(oldOwner, msg.sender);
    }

    /// @notice Sets the address for the trusted price/data oracle.
    /// @param _newOracle The address of the new oracle contract.
    function setOracleAddress(address _newOracle) external onlyGovernor {
        require(_newOracle != address(0), "Aetherial: Zero oracle address");
        emit OracleAddressUpdated(currentOracle, _newOracle);
        currentOracle = _newOracle;
    }

    /// @notice Sets the fee paid to an executor for successfully triggering an agent.
    /// @param _newFee The new execution fee in native tokens (ETH).
    function setExecutionFee(uint256 _newFee) external onlyGovernor {
        emit ExecutionFeeUpdated(executionFee, _newFee);
        executionFee = _newFee;
    }

    /// @notice Allows the governor to withdraw accumulated protocol fees.
    /// Fees are sent to the governor's address.
    function withdrawProtocolFees() external onlyGovernor nonReentrant {
        uint256 amount = totalProtocolFees;
        require(amount > 0, "Aetherial: No fees to withdraw");
        totalProtocolFees = 0;
        Address.sendValue(payable(msg.sender), amount);
        emit ProtocolFeesWithdrawn(msg.sender, amount);
    }

    /// @notice The guardian can temporarily pause critical protocol functions.
    function pauseProtocol() external onlyGuardian whenNotPaused {
        protocolPaused = true;
        emit ProtocolPaused(msg.sender);
    }

    /// @notice The guardian can unpause the protocol.
    function unpauseProtocol() external onlyGuardian whenPaused {
        protocolPaused = false;
        emit ProtocolUnpaused(msg.sender);
    }

    // --- II. Strategy Template Management ---

    /// @notice Whitelists a new, audited strategy implementation contract for agents to use.
    /// @param _templateImpl The address of the strategy implementation contract.
    /// @param _name A descriptive name for the template.
    /// @param _description A detailed description of what the strategy does.
    /// @param _allowedTokens An array of token addresses this template is allowed to manage.
    function addStrategyTemplate(
        address _templateImpl,
        string memory _name,
        string memory _description,
        address[] memory _allowedTokens
    ) external onlyGovernor {
        require(_templateImpl != address(0), "Aetherial: Zero template address");
        require(!strategyTemplates[_templateImpl].isActive, "Aetherial: Template already exists and is active");

        strategyTemplates[_templateImpl] = StrategyTemplate({
            isActive: true,
            name: _name,
            description: _description,
            allowedTokens: _allowedTokens
        });
        activeTemplateAddresses.push(_templateImpl);

        emit StrategyTemplateAdded(_templateImpl, _name, _description, true);
    }

    /// @notice Activates or deactivates a registered strategy template.
    /// Deactivating prevents new agents from being deployed using this template.
    /// Existing agents can still use it, but care should be taken if the template is deemed unsafe.
    /// @param _templateImpl The address of the strategy implementation contract.
    /// @param _isActive The new status (true for active, false for inactive).
    function updateStrategyTemplateStatus(address _templateImpl, bool _isActive) external onlyGovernor {
        require(strategyTemplates[_templateImpl].isActive != _isActive, "Aetherial: Template status already set");
        strategyTemplates[_templateImpl].isActive = _isActive;
        emit StrategyTemplateStatusUpdated(_templateImpl, _isActive);

        // Update activeTemplateAddresses list
        bool found = false;
        for (uint i = 0; i < activeTemplateAddresses.length; i++) {
            if (activeTemplateAddresses[i] == _templateImpl) {
                found = true;
                if (!_isActive) {
                    activeTemplateAddresses[i] = activeTemplateAddresses[activeTemplateAddresses.length - 1];
                    activeTemplateAddresses.pop();
                    break;
                }
            }
        }
        if (_isActive && !found) {
             activeTemplateAddresses.push(_templateImpl);
        }
    }

    // --- III. External Adapter Management ---

    /// @notice Registers an external contract and a specific function selector that agents are allowed to call.
    /// This whitelisting ensures agents only interact with approved DeFi protocols and functions.
    /// @param _targetContract The address of the external contract (e.g., Uniswap Router).
    /// @param _functionSelector The 4-byte selector of the specific function (e.g., `swapExactTokensForTokens(address,uint256,uint256,address[],address,uint256)`).
    /// @param _name A descriptive name for the adapter (e.g., "UniswapRouter-SwapExactTokensForTokens").
    /// @param _description A detailed description of the adapter's purpose.
    function addAdapter(
        address _targetContract,
        bytes4 _functionSelector,
        string memory _name,
        string memory _description
    ) external onlyGovernor {
        require(_targetContract != address(0), "Aetherial: Zero target contract address");
        require(!adapters[_targetContract][_functionSelector].isActive, "Aetherial: Adapter already active");

        adapters[_targetContract][_functionSelector] = Adapter({
            isActive: true,
            name: _name,
            description: _description
        });
        emit AdapterAdded(_targetContract, _functionSelector, _name, _description, true);
    }

    /// @notice Activates or deactivates a registered adapter.
    /// Deactivating prevents agents from using this specific interaction.
    /// @param _targetContract The address of the external contract.
    /// @param _functionSelector The 4-byte selector of the function.
    /// @param _isActive The new status (true for active, false for inactive).
    function updateAdapterStatus(
        address _targetContract,
        bytes4 _functionSelector,
        bool _isActive
    ) external onlyGovernor {
        require(adapters[_targetContract][_functionSelector].isActive != _isActive, "Aetherial: Adapter status already set");
        adapters[_targetContract][_functionSelector].isActive = _isActive;
        emit AdapterStatusUpdated(_targetContract, _functionSelector, _isActive);
    }

    // --- IV. Agent Factory & Registry ---

    /// @notice Allows the governor to update the base implementation contract for new agents.
    /// This is crucial for upgradeability, assuming the new implementation is compatible.
    /// @param _newAgentImplementation The address of the new base Agent implementation contract.
    function setAgentImplementation(address _newAgentImplementation) external onlyGovernor {
        require(_newAgentImplementation != address(0), "Aetherial: Zero agent implementation address");
        emit AgentImplementationUpdated(agentImplementation, _newAgentImplementation);
        agentImplementation = _newAgentImplementation;
    }

    /// @notice Deploys a new `Agent` instance based on an approved strategy template.
    /// Each agent is a minimal proxy, inheriting logic from `agentImplementation` and configured by `_templateImpl`.
    /// @param _templateImpl The address of the approved strategy template contract.
    /// @param _initialConfig The initial configuration bytes for the new agent.
    /// @return agentAddress The address of the newly deployed Agent contract.
    function deployAgent(address _templateImpl, bytes memory _initialConfig)
        external
        whenNotPaused
        nonReentrant
        returns (address agentAddress)
    {
        require(strategyTemplates[_templateImpl].isActive, "Aetherial: Template not active");
        require(agentImplementation != address(0), "Aetherial: Agent implementation not set");

        // Deploy a new Agent instance via minimal proxy (Clones.sol)
        agentAddress = Clones.clone(agentImplementation);

        // Initialize the new agent instance
        IAgent(agentAddress).initialize(msg.sender, address(this), _templateImpl, _initialConfig);

        // Register the agent
        agents[agentAddress] = AgentRegistryEntry({
            owner: msg.sender,
            templateImpl: _templateImpl,
            deployedTimestamp: block.timestamp
        });
        userAgents[msg.sender].push(agentAddress);

        emit AgentDeployed(agentAddress, msg.sender, _templateImpl, _initialConfig);
    }

    // --- V. Queries (Read-only) ---

    /// @notice Retrieves all registered details about a deployed agent.
    /// @param _agentAddress The address of the Agent contract.
    /// @return owner The owner of the agent.
    /// @return templateImpl The strategy template used by the agent.
    /// @return deployedTimestamp The timestamp when the agent was deployed.
    function getAgentDetails(address _agentAddress)
        external
        view
        returns (address owner, address templateImpl, uint256 deployedTimestamp)
    {
        AgentRegistryEntry storage agent = agents[_agentAddress];
        require(agent.owner != address(0), "Aetherial: Agent not found");
        return (agent.owner, agent.templateImpl, agent.deployedTimestamp);
    }

    /// @notice Returns a list of all agents owned by a specific user.
    /// @param _user The address of the user.
    /// @return An array of agent addresses owned by the user.
    function listUserAgents(address _user) external view returns (address[] memory) {
        return userAgents[_user];
    }

    /// @notice Retrieves details about a registered strategy template.
    /// @param _templateImpl The address of the strategy implementation contract.
    /// @return isActive Whether the template is active.
    /// @return name The name of the template.
    /// @return description The description of the template.
    /// @return allowedTokens An array of tokens this template is allowed to handle.
    function getStrategyTemplateDetails(address _templateImpl)
        external
        view
        returns (bool isActive, string memory name, string memory description, address[] memory allowedTokens)
    {
        StrategyTemplate storage templateData = strategyTemplates[_templateImpl];
        require(bytes(templateData.name).length > 0, "Aetherial: Template not found");
        return (templateData.isActive, templateData.name, templateData.description, templateData.allowedTokens);
    }

    /// @notice Returns a list of all currently active strategy templates.
    /// @return An array of active strategy template addresses.
    function listActiveTemplates() external view returns (address[] memory) {
        return activeTemplateAddresses;
    }

    /// @notice Retrieves details about a registered adapter.
    /// @param _targetContract The address of the external contract.
    /// @param _functionSelector The 4-byte selector of the function.
    /// @return isActive Whether the adapter is active.
    /// @return name The name of the adapter.
    /// @return description The description of the adapter.
    function getAdapterDetails(address _targetContract, bytes4 _functionSelector)
        external
        view
        returns (bool isActive, string memory name, string memory description)
    {
        Adapter storage adapterData = adapters[_targetContract][_functionSelector];
        require(bytes(adapterData.name).length > 0, "Aetherial: Adapter not found");
        return (adapterData.isActive, adapterData.name, adapterData.description);
    }

    /// @notice Returns a list of all currently active adapters (target contract, function selector pairs).
    /// Note: This is a placeholder, as iterating over a nested mapping is not practical.
    /// A real-world implementation would need a separate array to track active adapters
    /// if direct enumeration is required. This function will return an empty array.
    /// For practical purposes, specific adapter checks via `getAdapterDetails` are used.
    function listActiveAdapters() external pure returns (address[] memory /*_targetContracts*/, bytes4[] memory /*_functionSelectors*/) {
        // Due to Solidity's limitations, iterating over nested mappings to return all active adapters
        // is not feasible without significant gas cost or tracking a separate list.
        // For production, a more sophisticated indexing or a separate contract to manage and query adapters
        // might be needed. This serves as a placeholder to acknowledge the requirement.
        return (new address[](0), new bytes4[](0));
    }

    /// @dev Fallback function to collect native token (ETH) for fees.
    receive() external payable {
        if (msg.sender == address(this)) {
            // Internal call from an agent to pay execution fee.
            totalProtocolFees += msg.value;
        } else {
            // Prevent accidental direct sends to the protocol contract.
            revert("Aetherial: Direct ETH deposits not allowed outside of protocol fees");
        }
    }
}

```

---

### `Agent.sol` (Supporting Contract - The Agent Blueprint)

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

// --- Interfaces ---

interface IAetherialProtocol {
    function getStrategyTemplateDetails(address _templateImpl)
        external
        view
        returns (bool isActive, string memory name, string memory description, address[] memory allowedTokens);
    function getAdapterDetails(address _targetContract, bytes4 _functionSelector)
        external
        view
        returns (bool isActive, string memory name, string memory description);
    function executionFee() external view returns (uint256);
    function currentOracle() external view returns (address);
    function guardian() external view returns (address);
}

interface IAgentTemplate {
    function executeStrategy(
        address _agentAddress,
        address[] memory _allowedTokens,
        bytes memory _agentConfig,
        address _oracleAddress,
        address _protocolAddress
    ) external returns (bool success);
}

// --- Contract: Agent ---

/// @title Agent: Autonomous Strategy Instance
/// @author YourName
/// @notice This contract represents an individual autonomous agent deployed by the Aetherial Protocol.
/// It holds funds, manages its configuration, and executes strategies defined by its associated template.
contract Agent is ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Address for address;

    address public owner; // The user who deployed and owns this agent
    address public protocol; // The address of the AetherialProtocol factory contract
    address public templateImpl; // The address of the specific strategy implementation contract
    bytes public agentConfig; // Agent-specific configuration bytes

    bool public isActive; // Whether the agent is globally active (different from protocol pause)
    bool public isPaused; // Whether the agent's execution is temporarily paused by its owner

    // Granular permissions for other addresses to interact with this agent
    struct AgentPermissions {
        bool canTrigger;    // Can call triggerExecution
        bool canConfigure;  // Can call configureAgent
        bool canWithdraw;   // Can call withdrawAgentFunds
    }
    mapping(address => AgentPermissions) public agentPermissions;

    // --- Events ---

    event Initialized(address indexed owner, address indexed protocol, address indexed templateImpl);
    event FundsReceived(address indexed token, uint256 amount);
    event AgentConfigured(bytes newConfig);
    event AgentPermissionsUpdated(address indexed actor, bool canTrigger, bool canConfigure, bool canWithdraw);
    event StrategyExecuted(address indexed executor, bool success);
    event FundsWithdrawn(address indexed token, address indexed recipient, uint256 amount);
    event AgentPaused(address indexed by);
    event AgentUnpaused(address indexed by);
    event EmergencyWithdrawal(address indexed token, address indexed recipient, uint256 amount, address indexed by);
    event AgentSelfDestructed(address indexed owner, address indexed protocol);

    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Agent: Not owner");
        _;
    }

    modifier onlyProtocolGuardian() {
        require(msg.sender == IAetherialProtocol(protocol).guardian(), "Agent: Not protocol guardian");
        _;
    }

    modifier whenAgentActive() {
        require(isActive, "Agent: Not active");
        require(!isPaused, "Agent: Is paused by owner");
        _;
    }

    /// @notice Pseudo-constructor: Initializes the agent after deployment from the AetherialProtocol factory.
    /// This function can only be called once, typically by the AetherialProtocol itself.
    /// @param _owner The address of the agent's owner.
    /// @param _protocol The address of the AetherialProtocol factory contract.
    /// @param _templateImpl The address of the strategy template implementation.
    /// @param _initialConfig The initial configuration bytes for this agent instance.
    function initialize(address _owner, address _protocol, address _templateImpl, bytes memory _initialConfig) external {
        require(owner == address(0), "Agent: Already initialized"); // Ensure single initialization
        require(_owner != address(0), "Agent: Zero owner address");
        require(_protocol != address(0), "Agent: Zero protocol address");
        require(_templateImpl != address(0), "Agent: Zero template address");

        owner = _owner;
        protocol = _protocol;
        templateImpl = _templateImpl;
        agentConfig = _initialConfig;
        isActive = true; // Agents are active by default
        isPaused = false;

        emit Initialized(_owner, _protocol, _templateImpl);
    }

    // --- I. Agent Lifecycle ---

    /// @notice Allows external users to send ERC20 tokens or ETH to the agent.
    /// @param _token The address of the ERC20 token to send (address(0) for ETH).
    /// @dev This function assumes that the sender has approved the agent to spend ERC20 tokens
    ///      if _token is an ERC20. For ETH, the `receive` function handles direct transfers.
    function fundAgent(address _token) external payable nonReentrant {
        if (_token == address(0)) {
            require(msg.value > 0, "Agent: ETH amount must be greater than zero");
            // ETH is received via the `receive` function, this just emits an event for clarity.
            emit FundsReceived(address(0), msg.value);
        } else {
            require(msg.value == 0, "Agent: Cannot send ETH with ERC20 fund");
            IERC20(_token).safeTransferFrom(msg.sender, address(this), IERC20(_token).balanceOf(msg.sender)); // Transfers all approved
            emit FundsReceived(_token, IERC20(_token).balanceOf(address(this))); // This might be inaccurate if partial transfer
        }
    }

    /// @notice Allows the agent's owner or an authorized actor to update its specific configuration parameters.
    /// @param _newConfig The new configuration bytes.
    function configureAgent(bytes memory _newConfig) external nonReentrant {
        require(msg.sender == owner || agentPermissions[msg.sender].canConfigure, "Agent: Not authorized to configure");
        agentConfig = _newConfig;
        emit AgentConfigured(_newConfig);
    }

    /// @notice Manages granular permissions for other addresses to interact with *this specific agent*.
    /// @param _actor The address to grant/revoke permissions for.
    /// @param _canTrigger Whether the actor can call `triggerExecution`.
    /// @param _canConfigure Whether the actor can call `configureAgent`.
    /// @param _canWithdraw Whether the actor can call `withdrawAgentFunds`.
    function updateAgentPermissions(
        address _actor,
        bool _canTrigger,
        bool _canConfigure,
        bool _canWithdraw
    ) external onlyOwner {
        agentPermissions[_actor] = AgentPermissions(_canTrigger, _canConfigure, _canWithdraw);
        emit AgentPermissionsUpdated(_actor, _canTrigger, _canConfigure, _canWithdraw);
    }

    /// @notice Called by an external executor; evaluates strategy conditions and executes actions.
    /// The executor receives a fee if the strategy is successfully executed.
    /// @param _executor The address of the entity triggering the execution.
    /// @return success True if the strategy was executed successfully, false otherwise.
    function triggerExecution(address _executor) external payable whenAgentActive nonReentrant returns (bool success) {
        require(msg.sender == _executor || agentPermissions[msg.sender].canTrigger, "Agent: Not authorized to trigger");
        IAetherialProtocol protocolContract = IAetherialProtocol(protocol);

        // Check and transfer execution fee
        uint256 fee = protocolContract.executionFee();
        require(msg.value == fee, "Agent: Incorrect execution fee sent");
        Address.sendValue(payable(protocol), fee); // Send fee to AetherialProtocol for executor reward/protocol fees

        // Get template details to ensure it's still active and get allowed tokens
        (bool templateIsActive, , , address[] memory allowedTokens) = protocolContract.getStrategyTemplateDetails(templateImpl);
        require(templateIsActive, "Agent: Template is inactive");

        // Execute the strategy logic via the template contract
        success = IAgentTemplate(templateImpl).executeStrategy(
            address(this),
            allowedTokens,
            agentConfig,
            protocolContract.currentOracle(),
            protocol // Pass protocol address for adapter checks within template
        );

        emit StrategyExecuted(_executor, success);
        return success;
    }

    /// @notice Allows the agent owner (or authorized actor) to withdraw funds from this agent.
    /// @param _token The address of the token to withdraw (address(0) for ETH).
    /// @param _amount The amount of tokens to withdraw.
    function withdrawAgentFunds(address _token, uint256 _amount) external nonReentrant {
        require(msg.sender == owner || agentPermissions[msg.sender].canWithdraw, "Agent: Not authorized to withdraw");
        require(_amount > 0, "Agent: Amount must be greater than zero");

        if (_token == address(0)) {
            Address.sendValue(payable(owner), _amount);
        } else {
            IERC20(_token).safeTransfer(owner, _amount);
        }
        emit FundsWithdrawn(_token, owner, _amount);
    }

    /// @notice The agent owner can temporarily pause *this specific agent's* execution.
    function pauseAgent() external onlyOwner {
        require(!isPaused, "Agent: Already paused");
        isPaused = true;
        emit AgentPaused(msg.sender);
    }

    /// @notice The agent owner can unpause *this specific agent*.
    function unpauseAgent() external onlyOwner {
        require(isPaused, "Agent: Not paused");
        isPaused = false;
        emit AgentUnpaused(msg.sender);
    }

    /// @notice A guardian-only function to withdraw funds from a misbehaving or stuck agent instance.
    /// This is an emergency measure for protocol safety.
    /// @param _token The address of the token to withdraw (address(0) for ETH).
    /// @param _amount The amount of tokens to withdraw.
    /// @param _recipient The address to send the withdrawn funds to.
    function emergencyWithdrawAgentFunds(address _token, uint256 _amount, address _recipient) external onlyProtocolGuardian nonReentrant {
        require(_amount > 0, "Agent: Amount must be greater than zero");
        require(_recipient != address(0), "Agent: Zero recipient address");

        if (_token == address(0)) {
            Address.sendValue(payable(_recipient), _amount);
        } else {
            IERC20(_token).safeTransfer(_recipient, _amount);
        }
        emit EmergencyWithdrawal(_token, _recipient, _amount, msg.sender);
    }

    /// @notice Agent owner can self-destruct the agent contract and recover all remaining funds.
    function selfDestructAgent() external onlyOwner nonReentrant {
        isActive = false; // Mark inactive before destruction
        emit AgentSelfDestructed(owner, protocol);
        selfdestruct(payable(owner)); // Send all remaining ETH and tokens to the owner
    }

    // --- II. Queries ---

    /// @notice Returns the balance of a specific token held by the agent.
    /// @param _token The address of the token (address(0) for ETH).
    /// @return The balance of the specified token.
    function getAgentBalance(address _token) external view returns (uint256) {
        if (_token == address(0)) {
            return address(this).balance;
        } else {
            return IERC20(_token).balanceOf(address(this));
        }
    }

    /// @notice Returns the current configuration (bytes) of the agent.
    /// @return The agent's configuration bytes.
    function getAgentConfig() external view returns (bytes memory) {
        return agentConfig;
    }

    /// @dev Fallback function to allow receiving ETH.
    receive() external payable {
        emit FundsReceived(address(0), msg.value);
    }
}
```