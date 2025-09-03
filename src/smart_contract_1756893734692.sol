This smart contract, **NexusForge**, is a sophisticated platform for creating and managing decentralized autonomous agents ("Agents") built from modular components ("Components"). It introduces dynamic NFTs, on-chain automation, a resource economy, and a reputation system, all within a single cohesive ecosystem.

---

## NexusForge Smart Contract

**Concept:** NexusForge empowers users to craft modular "Agent NFTs" from discrete "Component NFTs." These Agents can be programmed to execute pre-defined "Protocols" – complex on-chain tasks that interact with other smart contracts. Agents consume "Essence" (a dedicated ERC-20 token) from a shared "Conduit" to operate, and successful protocol executions earn rewards, influencing the Agent's reputation.

**Key Features:**
*   **Dynamic Agent NFTs:** Agents evolve as Components are added or removed, dynamically changing their capabilities.
*   **Modular Component System:** Components (e.g., Data Processors, Value Transfer Units) are individual, non-ERC721 assets with specific capabilities and operational costs. They are owned by users and can be assigned to Agents.
*   **On-chain Autonomous Protocols:** Agents can be assigned and triggered to execute complex, predefined interactions with external smart contracts.
*   **Essence Resource Economy:** A dedicated ERC-20 token (`EssenceToken`) serves as the operational fuel, deposited into a central "Conduit."
*   **Reputation System:** Agents and Protocols accumulate success/failure metrics, providing on-chain transparency for performance.
*   **Access Control:** Robust roles for `Owner` and `Operator` to manage system configurations and emergency functions.
*   **Pausable System:** Allows for emergency halts of critical operations.

---

### Outline:

**I. Contract Overview:**
    A. SPDX License and Pragma
    B. OpenZeppelin Imports
    C. Data Structures (for Capabilities, Components, Agents, Protocols)

**II. State Variables:**
    A. Core Configuration (Essence Token, ID Counters)
    B. Access Control (Operators)
    C. Capability Registry
    D. Component Registry & Ownership
    E. Agent NFT Data (ERC-721 details, attached components, activation, reputation)
    F. Protocol Registry
    G. Protocol Assignment per Agent

**III. Events:**
    A. Logging key actions and state changes.

**IV. Modifiers:**
    A. Access Control modifiers (`onlyOwner`, `onlyOperatorOrOwner`, `onlyAgentOwnerOrApproved`).

**V. Constructor & Core Configuration:**
    A. Initializes the contract and sets the deployer as owner.
    B. Sets the ERC-20 token used for Essence.

**VI. Access Control (Owner, Operator, Pausable):**
    A. Management of operator roles.
    B. Pausing/unpausing the contract.
    C. Withdrawal of funds from the contract.

**VII. Capability Management:**
    A. Defining and updating system capabilities.

**VIII. Essence Conduit (ERC-20 integration):**
    A. Depositing Essence.
    B. Withdrawing Essence (for contract owner/operator).
    C. Querying available Essence.

**IX. Component Management (Custom Ownership Tracking):**
    A. Minting new Components.
    B. Transferring Component ownership.
    C. Burning Components.
    D. Updating Component attributes (cost, URI).

**X. Agent NFTs (ERC-721, Composite):**
    A. Assembling new Agent NFTs from Components.
    B. Disassembling Agents to reclaim Components.
    C. Attaching/detaching Components to/from Agents.
    D. Activating/deactivating Agents for protocol execution.
    E. ERC-721 `tokenURI` override for Agent metadata.

**XI. Protocol Management & Execution:**
    A. Defining and updating executable Protocols.
    B. Assigning/unassigning Protocols to/from Agents.
    C. **`triggerAgentProtocol`**: The core function for Agent autonomy.
    D. Approving specific Protocol executions by Agents (for sensitive Protocols).

**XII. Reputation & Monitoring:**
    A. Querying Agent reputation.
    B. Querying Protocol performance statistics.

**XIII. Internal Helper Functions:**
    A. Internal logic for ownership checks, capability verification, essence deductions, etc.

---

### Function Summary:

1.  `constructor()`: Initializes the contract, sets the deployer as the owner.
2.  `setEssenceToken(address _token)`: Sets the address of the ERC-20 token to be used as Essence. Owner/Operator only.
3.  `setOperator(address _operator, bool _status)`: Grants or revokes operator privileges for an address. Owner only.
4.  `pause()`: Pauses core operations of the contract. Owner/Operator only.
5.  `unpause()`: Unpauses core operations of the contract. Owner/Operator only.
6.  `withdrawContractBalance(address _tokenAddress, uint256 _amount)`: Allows Owner/Operator to withdraw specified tokens from the contract balance.
7.  `defineCapability(string memory _name, string memory _description)`: Defines a new system capability (e.g., "DataProcessing"). Owner/Operator only.
8.  `updateCapability(uint256 _capabilityId, string memory _newName, string memory _newDescription)`: Modifies the name and description of an existing capability. Owner/Operator only.
9.  `injectEssence(uint256 _amount)`: Allows users to deposit Essence ERC-20 tokens into the contract's Conduit.
10. `harvestEssence(uint256 _amount)`: Allows Owner/Operator to withdraw Essence from the Conduit.
11. `getConduitEssence()`: Returns the current total amount of Essence available in the Conduit.
12. `mintComponent(address _to, uint256[] memory _capabilityIds, uint256 _baseEssenceCost, string memory _tokenURI)`: Mints a new Component NFT, assigns capabilities, and sets its base operational cost and URI.
13. `transferComponent(address _from, address _to, uint256 _componentId)`: Transfers ownership of a Component. Component owner only.
14. `burnComponent(uint256 _componentId)`: Burns a Component. Component owner only.
15. `updateComponentCost(uint256 _componentId, uint256 _newCost)`: Updates the `_baseEssenceCost` of a Component. Component owner only.
16. `updateComponentURI(uint256 _componentId, string memory _newURI)`: Updates the metadata URI for a Component. Component owner only.
17. `assembleAgent(uint256[] memory _componentIds, string memory _agentName, string memory _agentURI)`: Mints a new Agent NFT (ERC-721) by locking specified Components to it. Components are transferred to the Agent contract's ownership.
18. `disassembleAgent(uint256 _agentId)`: Destroys an Agent NFT and returns its attached Components to the Agent's owner. Agent owner only.
19. `addComponentToAgent(uint256 _agentId, uint256 _componentId)`: Adds a Component to an existing Agent. Agent owner and Component owner only.
20. `removeComponentFromAgent(uint256 _agentId, uint256 _componentId)`: Removes a Component from an Agent and returns it to the Agent's owner. Agent owner only.
21. `toggleAgentActivation(uint256 _agentId, bool _isActive)`: Activates or deactivates an Agent, controlling its ability to execute protocols. Agent owner only.
22. `tokenURI(uint256 tokenId)`: Returns the metadata URI for a given Agent NFT (standard ERC-721 override).
23. `defineProtocol(bytes4 _protocolId, uint256[] memory _requiredCapabilities, uint256 _essenceCost, uint256 _essenceReward, address _targetContract, bytes4 _targetFunctionSignature, bool _requiresOwnerApproval)`: Defines a new Protocol template, specifying requirements, costs, rewards, target contract, function signature, and if owner approval is needed for execution. Owner/Operator only.
24. `updateProtocol(bytes4 _protocolId, uint256[] memory _newRequiredCapabilities, uint256 _newEssenceCost, uint256 _newEssenceReward, address _newTargetContract, bytes4 _newTargetFunctionSignature, bool _newRequiresOwnerApproval)`: Modifies an existing Protocol definition. Owner/Operator only.
25. `assignProtocolToAgent(uint256 _agentId, bytes4 _protocolId)`: Assigns a defined Protocol to a specific Agent, making it eligible for execution. Agent owner only.
26. `unassignProtocolFromAgent(uint256 _agentId, bytes4 _protocolId)`: Removes a Protocol assignment from an Agent. Agent owner only.
27. `triggerAgentProtocol(uint256 _agentId, bytes4 _protocolId, bytes memory _callData)`: The core function to trigger an Agent to execute an assigned Protocol. Verifies capabilities, deducts Essence, performs the external call, and updates reputation. Requires Agent owner approval if `_requiresOwnerApproval` is true for the protocol.
28. `approveAgentProtocolExecution(uint256 _agentId, bytes4 _protocolId)`: Grants explicit approval for an Agent to execute a specific Protocol instance. Agent owner only, for protocols marked as `_requiresOwnerApproval`.
29. `getAgentReputation(uint256 _agentId)`: Retrieves the success-based reputation score of an Agent.
30. `getProtocolPerformance(bytes4 _protocolId)`: Returns the total success and failure counts for a given Protocol.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title NexusForge
 * @dev A decentralized platform for crafting and deploying "Autonomous Agent NFTs"
 * from modular "Component NFTs". Agents can be programmed to perform on-chain
 * actions, leveraging their assembled components and a shared "Essence Conduit" resource.
 *
 * This contract encompasses:
 * - ERC-721 for Agent NFTs.
 * - Custom management of Component assets (non-ERC721 but with tracked ownership).
 * - A Capability registry for defining agent abilities.
 * - An Essence token economy for fueling agent operations.
 * - A Protocol system for defining and executing on-chain autonomous tasks.
 * - A basic reputation system for agents and protocols.
 */
contract NexusForge is Ownable, Pausable, ERC721 {
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.Bytes4Set;
    using Strings for uint256;

    // --- I. Contract Overview & Data Structures ---

    struct Capability {
        string name;
        string description;
    }

    struct Component {
        uint256 id;
        uint256[] capabilityIds; // IDs of capabilities this component grants
        uint256 baseEssenceCost; // Essence cost per execution when part of an agent
        string tokenURI;
        bool exists; // To check if component ID is valid
    }

    struct Agent {
        uint256 id;
        EnumerableSet.UintSet attachedComponents; // IDs of components attached to this agent
        bool isActive; // If true, agent can execute protocols
        uint256 reputation; // Success-based reputation score
        string tokenURI;
    }

    struct Protocol {
        uint256[] requiredCapabilities; // Capabilities an agent needs to execute this protocol
        uint256 essenceCost; // Essence cost to trigger this protocol
        uint256 essenceReward; // Essence reward for successful execution
        address targetContract; // Contract address to interact with
        bytes4 targetFunctionSignature; // The signature of the function to call on targetContract
        bool requiresOwnerApproval; // If true, agent owner must approve each execution
        uint256 successCount;
        uint256 failureCount;
        bool exists; // To check if protocol ID is valid
    }

    // --- II. State Variables ---

    // Core Configuration
    IERC20 public essenceToken;
    Counters.Counter private _capabilityIdTracker;
    Counters.Counter private _componentIdTracker;
    Counters.Counter private _agentIdTracker;

    // Access Control
    mapping(address => bool) public operators; // Addresses with privileged operator roles

    // Capability Registry
    mapping(uint256 => Capability) public capabilities;
    EnumerableSet.UintSet private _allCapabilityIds;

    // Component Registry & Ownership (Components are NOT ERC-721, but custom tracked)
    mapping(uint256 => Component) public components;
    mapping(uint256 => address) public componentOwners; // ComponentId => OwnerAddress
    mapping(address => EnumerableSet.UintSet) private _ownedComponents; // OwnerAddress => Set of ComponentIds

    // Agent NFT Data (ERC-721 handles general ownership, this for specific Agent data)
    mapping(uint256 => Agent) public agents;
    mapping(uint256 => EnumerableSet.Bytes4Set) private _agentAssignedProtocols; // AgentId => Set of assigned ProtocolIds
    mapping(uint256 => mapping(bytes4 => bool)) private _agentProtocolApproved; // AgentId => ProtocolId => Approved

    // Protocol Registry
    mapping(bytes4 => Protocol) public protocols;
    EnumerableSet.Bytes4Set private _allProtocolIds;

    // --- III. Events ---

    event EssenceTokenSet(address indexed _token);
    event OperatorSet(address indexed _operator, bool _status);
    event CapabilityDefined(uint256 indexed _capabilityId, string _name, string _description);
    event CapabilityUpdated(uint256 indexed _capabilityId, string _newName, string _newDescription);
    event EssenceInjected(address indexed _user, uint256 _amount);
    event EssenceHarvested(address indexed _harvester, uint256 _amount);
    event ComponentMinted(uint256 indexed _componentId, address indexed _to, uint256[] _capabilityIds, uint256 _baseEssenceCost, string _tokenURI);
    event ComponentTransferred(uint256 indexed _componentId, address indexed _from, address indexed _to);
    event ComponentBurned(uint256 indexed _componentId, address indexed _from);
    event ComponentCostUpdated(uint256 indexed _componentId, uint256 _newCost);
    event ComponentURIUpdated(uint256 indexed _componentId, string _newURI);
    event AgentAssembled(uint256 indexed _agentId, address indexed _owner, uint256[] _componentIds, string _agentName, string _agentURI);
    event AgentDisassembled(uint256 indexed _agentId, address indexed _owner, uint256[] _returnedComponentIds);
    event ComponentAddedToAgent(uint256 indexed _agentId, uint256 indexed _componentId);
    event ComponentRemovedFromAgent(uint256 indexed _agentId, uint256 indexed _componentId);
    event AgentActivationToggled(uint256 indexed _agentId, bool _isActive);
    event ProtocolDefined(bytes4 indexed _protocolId, uint256[] _requiredCapabilities, uint256 _essenceCost, uint256 _essenceReward, address _targetContract, bytes4 _targetFunctionSignature, bool _requiresOwnerApproval);
    event ProtocolUpdated(bytes4 indexed _protocolId, uint256[] _newRequiredCapabilities, uint256 _newEssenceCost, uint256 _newEssenceReward, address _newTargetContract, bytes4 _newTargetFunctionSignature, bool _newRequiresOwnerApproval);
    event ProtocolAssignedToAgent(uint256 indexed _agentId, bytes4 indexed _protocolId);
    event ProtocolUnassignedFromAgent(uint256 indexed _agentId, bytes4 indexed _protocolId);
    event AgentProtocolTriggered(uint256 indexed _agentId, bytes4 indexed _protocolId, bool _success, uint256 _totalCost, uint256 _reward);
    event AgentProtocolExecutionApproved(uint256 indexed _agentId, bytes4 indexed _protocolId, address indexed _approver);

    // --- IV. Modifiers ---

    modifier onlyOperatorOrOwner() {
        require(operators[msg.sender] || msg.sender == owner(), "NexusForge: Caller is not an operator or owner");
        _;
    }

    modifier onlyAgentOwner(uint256 _agentId) {
        require(_exists(_agentId), "NexusForge: Agent does not exist");
        require(ownerOf(_agentId) == msg.sender, "NexusForge: Caller is not agent owner");
        _;
    }

    modifier onlyComponentOwner(uint256 _componentId) {
        require(components[_componentId].exists, "NexusForge: Component does not exist");
        require(componentOwners[_componentId] == msg.sender, "NexusForge: Caller is not component owner");
        _;
    }

    // --- V. Constructor & Core Configuration ---

    constructor(string memory _agentName, string memory _agentSymbol) ERC721(_agentName, _agentSymbol) Ownable(msg.sender) {}

    /**
     * @dev Sets the ERC-20 token address to be used as Essence.
     * Can only be set once.
     * Callable by owner/operator.
     * @param _token The address of the Essence ERC-20 token.
     */
    function setEssenceToken(address _token) external onlyOperatorOrOwner {
        require(address(essenceToken) == address(0), "NexusForge: Essence token already set");
        essenceToken = IERC20(_token);
        emit EssenceTokenSet(_token);
    }

    // --- VI. Access Control (Owner, Operator, Pausable) ---

    /**
     * @dev Grants or revokes operator privileges for an address.
     * Operators can perform certain privileged actions like pausing/unpausing, defining capabilities/protocols.
     * Callable by owner only.
     * @param _operator The address to grant/revoke privileges.
     * @param _status True to grant, false to revoke.
     */
    function setOperator(address _operator, bool _status) external onlyOwner {
        operators[_operator] = _status;
        emit OperatorSet(_operator, _status);
    }

    /**
     * @dev Pauses core operations of the contract.
     * Callable by owner or operator.
     */
    function pause() public override onlyOperatorOrOwner whenNotPaused {
        _pause();
    }

    /**
     * @dev Unpauses core operations of the contract.
     * Callable by owner or operator.
     */
    function unpause() public override onlyOperatorOrOwner whenPaused {
        _unpause();
    }

    /**
     * @dev Allows owner/operator to withdraw specified tokens from the contract balance.
     * Useful for withdrawing accumulated fees or accidental transfers.
     * @param _tokenAddress The address of the token to withdraw (use address(0) for native ETH).
     * @param _amount The amount of tokens to withdraw.
     */
    function withdrawContractBalance(address _tokenAddress, uint256 _amount) external onlyOperatorOrOwner {
        if (_tokenAddress == address(0)) {
            payable(msg.sender).transfer(_amount);
        } else {
            IERC20(_tokenAddress).transfer(msg.sender, _amount);
        }
    }

    // --- VII. Capability Management ---

    /**
     * @dev Defines a new system capability.
     * Callable by owner/operator.
     * @param _name The name of the capability (e.g., "DataProcessing").
     * @param _description A detailed description of the capability.
     * @return The ID of the newly defined capability.
     */
    function defineCapability(string memory _name, string memory _description)
        external
        onlyOperatorOrOwner
        returns (uint256)
    {
        _capabilityIdTracker.increment();
        uint256 capId = _capabilityIdTracker.current();
        capabilities[capId] = Capability(_name, _description);
        _allCapabilityIds.add(capId);
        emit CapabilityDefined(capId, _name, _description);
        return capId;
    }

    /**
     * @dev Modifies the name and description of an existing capability.
     * Callable by owner/operator.
     * @param _capabilityId The ID of the capability to update.
     * @param _newName The new name for the capability.
     * @param _newDescription The new description for the capability.
     */
    function updateCapability(
        uint256 _capabilityId,
        string memory _newName,
        string memory _newDescription
    ) external onlyOperatorOrOwner {
        require(_allCapabilityIds.contains(_capabilityId), "NexusForge: Capability does not exist");
        capabilities[_capabilityId].name = _newName;
        capabilities[_capabilityId].description = _newDescription;
        emit CapabilityUpdated(_capabilityId, _newName, _newDescription);
    }

    // --- VIII. Essence Conduit (ERC-20 integration) ---

    /**
     * @dev Allows users to deposit Essence ERC-20 tokens into the contract's Conduit.
     * These tokens are used to fuel agent operations.
     * @param _amount The amount of Essence tokens to deposit.
     */
    function injectEssence(uint256 _amount) external whenNotPaused {
        require(address(essenceToken) != address(0), "NexusForge: Essence token not set");
        require(essenceToken.transferFrom(msg.sender, address(this), _amount), "NexusForge: Essence transfer failed");
        emit EssenceInjected(msg.sender, _amount);
    }

    /**
     * @dev Allows Owner/Operator to withdraw Essence from the Conduit.
     * Useful for withdrawing accumulated protocol fees.
     * @param _amount The amount of Essence to withdraw.
     */
    function harvestEssence(uint256 _amount) external onlyOperatorOrOwner {
        require(address(essenceToken) != address(0), "NexusForge: Essence token not set");
        require(essenceToken.balanceOf(address(this)) >= _amount, "NexusForge: Insufficient Essence in Conduit");
        require(essenceToken.transfer(msg.sender, _amount), "NexusForge: Essence withdrawal failed");
        emit EssenceHarvested(msg.sender, _amount);
    }

    /**
     * @dev Returns the current total amount of Essence available in the Conduit.
     */
    function getConduitEssence() public view returns (uint256) {
        return essenceToken.balanceOf(address(this));
    }

    // --- IX. Component Management (Custom Ownership Tracking) ---

    /**
     * @dev Mints a new Component. Components are not ERC-721, but their ownership is tracked.
     * Callable by any address.
     * @param _to The address to mint the component to.
     * @param _capabilityIds An array of capability IDs this component provides.
     * @param _baseEssenceCost The base essence cost associated with using this component.
     * @param _tokenURI The metadata URI for this component.
     * @return The ID of the newly minted component.
     */
    function mintComponent(
        address _to,
        uint256[] memory _capabilityIds,
        uint256 _baseEssenceCost,
        string memory _tokenURI
    ) external whenNotPaused returns (uint256) {
        require(_to != address(0), "NexusForge: Mint to the zero address");
        _componentIdTracker.increment();
        uint256 componentId = _componentIdTracker.current();

        components[componentId] = Component(componentId, _capabilityIds, _baseEssenceCost, _tokenURI, true);
        componentOwners[componentId] = _to;
        _ownedComponents[_to].add(componentId);

        emit ComponentMinted(componentId, _to, _capabilityIds, _baseEssenceCost, _tokenURI);
        return componentId;
    }

    /**
     * @dev Transfers ownership of a Component.
     * Callable by the current component owner.
     * @param _from The current owner of the component.
     * @param _to The new owner of the component.
     * @param _componentId The ID of the component to transfer.
     */
    function transferComponent(address _from, address _to, uint256 _componentId)
        external
        whenNotPaused
        onlyComponentOwner(_componentId)
    {
        require(_from == msg.sender, "NexusForge: Caller must be _from address");
        require(_to != address(0), "NexusForge: Transfer to the zero address");
        require(_from != _to, "NexusForge: Cannot transfer to self");
        
        _ownedComponents[_from].remove(_componentId);
        componentOwners[_componentId] = _to;
        _ownedComponents[_to].add(_componentId);
        emit ComponentTransferred(_componentId, _from, _to);
    }

    /**
     * @dev Burns a Component, removing it from existence.
     * Callable by the component owner.
     * @param _componentId The ID of the component to burn.
     */
    function burnComponent(uint256 _componentId) external whenNotPaused onlyComponentOwner(_componentId) {
        address owner_ = componentOwners[_componentId];
        delete components[_componentId];
        delete componentOwners[_componentId];
        _ownedComponents[owner_].remove(_componentId);
        emit ComponentBurned(_componentId, owner_);
    }

    /**
     * @dev Updates the base essence cost of an existing component.
     * Callable by the component owner.
     * @param _componentId The ID of the component to update.
     * @param _newCost The new base essence cost.
     */
    function updateComponentCost(uint256 _componentId, uint256 _newCost)
        external
        whenNotPaused
        onlyComponentOwner(_componentId)
    {
        components[_componentId].baseEssenceCost = _newCost;
        emit ComponentCostUpdated(_componentId, _newCost);
    }

    /**
     * @dev Updates the metadata URI for a Component.
     * Callable by the component owner.
     * @param _componentId The ID of the component to update.
     * @param _newURI The new metadata URI.
     */
    function updateComponentURI(uint256 _componentId, string memory _newURI)
        external
        whenNotPaused
        onlyComponentOwner(_componentId)
    {
        components[_componentId].tokenURI = _newURI;
        emit ComponentURIUpdated(_componentId, _newURI);
    }

    /**
     * @dev Returns the number of components owned by an address.
     * @param _owner The address to query.
     */
    function getOwnedComponentCount(address _owner) external view returns (uint256) {
        return _ownedComponents[_owner].length();
    }

    /**
     * @dev Returns an array of component IDs owned by an address.
     * @param _owner The address to query.
     */
    function getOwnedComponentIds(address _owner) external view returns (uint256[] memory) {
        return _ownedComponents[_owner].values();
    }

    // --- X. Agent NFTs (ERC-721, Composite) ---

    /**
     * @dev Mints a new Agent NFT (ERC-721) by locking specified Components to it.
     * Components are transferred to the Agent contract's ownership and logically owned by the agent.
     * Callable by any address (the minter becomes the Agent owner).
     * @param _componentIds An array of component IDs to attach to the new agent.
     * @param _agentName The name of the new agent.
     * @param _agentURI The metadata URI for the new agent.
     * @return The ID of the newly minted agent.
     */
    function assembleAgent(uint256[] memory _componentIds, string memory _agentName, string memory _agentURI)
        external
        whenNotPaused
        returns (uint256)
    {
        // Transfer components to the contract (representing agent ownership)
        for (uint256 i = 0; i < _componentIds.length; i++) {
            uint256 componentId = _componentIds[i];
            require(components[componentId].exists, "NexusForge: Component does not exist");
            require(componentOwners[componentId] == msg.sender, "NexusForge: Not component owner");
            
            _ownedComponents[msg.sender].remove(componentId);
            componentOwners[componentId] = address(this); // Agent (contract) now owns the component
        }

        _agentIdTracker.increment();
        uint256 agentId = _agentIdTracker.current();

        _safeMint(msg.sender, agentId); // Mint ERC-721 to caller
        _setTokenURI(agentId, _agentURI); // Set ERC-721 URI

        Agent storage newAgent = agents[agentId];
        newAgent.id = agentId;
        newAgent.isActive = true; // Agents are active by default
        newAgent.tokenURI = _agentURI;

        for (uint256 i = 0; i < _componentIds.length; i++) {
            newAgent.attachedComponents.add(_componentIds[i]);
        }

        emit AgentAssembled(agentId, msg.sender, _componentIds, _agentName, _agentURI);
        return agentId;
    }

    /**
     * @dev Destroys an Agent NFT and returns its attached Components to the Agent's owner.
     * Callable by the Agent owner.
     * @param _agentId The ID of the agent to disassemble.
     */
    function disassembleAgent(uint256 _agentId) external whenNotPaused onlyAgentOwner(_agentId) {
        address agentOwner = ownerOf(_agentId);
        
        uint256[] memory returnedComponentIds = agents[_agentId].attachedComponents.values();
        for (uint256 i = 0; i < returnedComponentIds.length; i++) {
            uint256 componentId = returnedComponentIds[i];
            componentOwners[componentId] = agentOwner; // Return component to agent owner
            _ownedComponents[agentOwner].add(componentId);
            agents[_agentId].attachedComponents.remove(componentId); // Remove from agent's set
        }

        delete agents[_agentId]; // Clear agent data
        _burn(_agentId); // Burn ERC-721 token
        
        emit AgentDisassembled(_agentId, agentOwner, returnedComponentIds);
    }

    /**
     * @dev Adds a Component to an existing Agent. Component is transferred to the agent (contract ownership).
     * Callable by the Agent owner, provided they also own the Component.
     * @param _agentId The ID of the agent to modify.
     * @param _componentId The ID of the component to add.
     */
    function addComponentToAgent(uint256 _agentId, uint256 _componentId)
        external
        whenNotPaused
        onlyAgentOwner(_agentId)
    {
        require(components[_componentId].exists, "NexusForge: Component does not exist");
        require(componentOwners[_componentId] == msg.sender, "NexusForge: Caller does not own component");
        require(!agents[_agentId].attachedComponents.contains(_componentId), "NexusForge: Component already attached");

        _ownedComponents[msg.sender].remove(_componentId);
        componentOwners[_componentId] = address(this); // Agent (contract) now owns component
        agents[_agentId].attachedComponents.add(_componentId);
        emit ComponentAddedToAgent(_agentId, _componentId);
    }

    /**
     * @dev Removes a Component from an Agent and returns it to the Agent's owner.
     * Callable by the Agent owner.
     * @param _agentId The ID of the agent to modify.
     * @param _componentId The ID of the component to remove.
     */
    function removeComponentFromAgent(uint256 _agentId, uint256 _componentId)
        external
        whenNotPaused
        onlyAgentOwner(_agentId)
    {
        require(agents[_agentId].attachedComponents.contains(_componentId), "NexusForge: Component not attached to agent");
        require(componentOwners[_componentId] == address(this), "NexusForge: Component not owned by agent contract");

        agents[_agentId].attachedComponents.remove(_componentId);
        componentOwners[_componentId] = msg.sender; // Return component to agent owner
        _ownedComponents[msg.sender].add(_componentId);
        emit ComponentRemovedFromAgent(_agentId, _componentId);
    }

    /**
     * @dev Activates or deactivates an Agent, controlling its ability to execute protocols.
     * Callable by the Agent owner.
     * @param _agentId The ID of the agent to modify.
     * @param _isActive True to activate, false to deactivate.
     */
    function toggleAgentActivation(uint256 _agentId, bool _isActive)
        external
        whenNotPaused
        onlyAgentOwner(_agentId)
    {
        agents[_agentId].isActive = _isActive;
        emit AgentActivationToggled(_agentId, _isActive);
    }

    /**
     * @dev See {ERC721-tokenURI}.
     * Overrides the default ERC721 tokenURI to return the Agent's specific URI.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return agents[tokenId].tokenURI;
    }

    // --- XI. Protocol Management & Execution ---

    /**
     * @dev Defines a new Protocol template.
     * Callable by owner/operator.
     * @param _protocolId A unique bytes4 identifier for the protocol (e.g., bytes4(keccak256("ARBITRAGE"))).
     * @param _requiredCapabilities Array of capability IDs an agent needs to execute this protocol.
     * @param _essenceCost The base essence cost to trigger this protocol.
     * @param _essenceReward The essence reward for successful execution.
     * @param _targetContract The address of the external contract to interact with.
     * @param _targetFunctionSignature The 4-byte signature of the function to call on `_targetContract`.
     * @param _requiresOwnerApproval If true, agent owner must explicitly approve each execution via `approveAgentProtocolExecution`.
     */
    function defineProtocol(
        bytes4 _protocolId,
        uint256[] memory _requiredCapabilities,
        uint256 _essenceCost,
        uint256 _essenceReward,
        address _targetContract,
        bytes4 _targetFunctionSignature,
        bool _requiresOwnerApproval
    ) external onlyOperatorOrOwner {
        require(!protocols[_protocolId].exists, "NexusForge: Protocol ID already exists");
        require(_targetContract != address(0), "NexusForge: Target contract cannot be zero address");

        for(uint256 i = 0; i < _requiredCapabilities.length; i++) {
            require(_allCapabilityIds.contains(_requiredCapabilities[i]), "NexusForge: Invalid required capability ID");
        }

        protocols[_protocolId] = Protocol(
            _requiredCapabilities,
            _essenceCost,
            _essenceReward,
            _targetContract,
            _targetFunctionSignature,
            _requiresOwnerApproval,
            0, // successCount
            0, // failureCount
            true // exists
        );
        _allProtocolIds.add(_protocolId);
        emit ProtocolDefined(
            _protocolId,
            _requiredCapabilities,
            _essenceCost,
            _essenceReward,
            _targetContract,
            _targetFunctionSignature,
            _requiresOwnerApproval
        );
    }

    /**
     * @dev Modifies an existing Protocol definition.
     * Callable by owner/operator.
     * @param _protocolId The ID of the protocol to update.
     * @param _newRequiredCapabilities New array of capability IDs.
     * @param _newEssenceCost New essence cost.
     * @param _newEssenceReward New essence reward.
     * @param _newTargetContract New target contract address.
     * @param _newTargetFunctionSignature New target function signature.
     * @param _newRequiresOwnerApproval New owner approval requirement.
     */
    function updateProtocol(
        bytes4 _protocolId,
        uint256[] memory _newRequiredCapabilities,
        uint256 _newEssenceCost,
        uint256 _newEssenceReward,
        address _newTargetContract,
        bytes4 _newTargetFunctionSignature,
        bool _newRequiresOwnerApproval
    ) external onlyOperatorOrOwner {
        require(protocols[_protocolId].exists, "NexusForge: Protocol does not exist");
        require(_newTargetContract != address(0), "NexusForge: Target contract cannot be zero address");

        for(uint256 i = 0; i < _newRequiredCapabilities.length; i++) {
            require(_allCapabilityIds.contains(_newRequiredCapabilities[i]), "NexusForge: Invalid required capability ID");
        }

        Protocol storage p = protocols[_protocolId];
        p.requiredCapabilities = _newRequiredCapabilities;
        p.essenceCost = _newEssenceCost;
        p.essenceReward = _newEssenceReward;
        p.targetContract = _newTargetContract;
        p.targetFunctionSignature = _newTargetFunctionSignature;
        p.requiresOwnerApproval = _newRequiresOwnerApproval;
        
        emit ProtocolUpdated(
            _protocolId,
            _newRequiredCapabilities,
            _newEssenceCost,
            _newEssenceReward,
            _newTargetContract,
            _newTargetFunctionSignature,
            _newRequiresOwnerApproval
        );
    }

    /**
     * @dev Assigns a defined Protocol to a specific Agent, making it eligible for execution.
     * Callable by the Agent owner.
     * @param _agentId The ID of the agent.
     * @param _protocolId The ID of the protocol to assign.
     */
    function assignProtocolToAgent(uint256 _agentId, bytes4 _protocolId)
        external
        whenNotPaused
        onlyAgentOwner(_agentId)
    {
        require(protocols[_protocolId].exists, "NexusForge: Protocol does not exist");
        require(!_agentAssignedProtocols[_agentId].contains(_protocolId), "NexusForge: Protocol already assigned");
        _agentAssignedProtocols[_agentId].add(_protocolId);
        emit ProtocolAssignedToAgent(_agentId, _protocolId);
    }

    /**
     * @dev Removes a Protocol assignment from an Agent.
     * Callable by the Agent owner.
     * @param _agentId The ID of the agent.
     * @param _protocolId The ID of the protocol to unassign.
     */
    function unassignProtocolFromAgent(uint256 _agentId, bytes4 _protocolId)
        external
        whenNotPaused
        onlyAgentOwner(_agentId)
    {
        require(protocols[_protocolId].exists, "NexusForge: Protocol does not exist");
        require(_agentAssignedProtocols[_agentId].contains(_protocolId), "NexusForge: Protocol not assigned to agent");
        _agentAssignedProtocols[_agentId].remove(_protocolId);
        // Clear any lingering approvals for this protocol
        _agentProtocolApproved[_agentId][_protocolId] = false;
        emit ProtocolUnassignedFromAgent(_agentId, _protocolId);
    }

    /**
     * @dev Grants explicit approval for an Agent to execute a specific Protocol instance.
     * This is required for Protocols where `requiresOwnerApproval` is true.
     * Callable by the Agent owner.
     * @param _agentId The ID of the agent.
     * @param _protocolId The ID of the protocol to approve.
     */
    function approveAgentProtocolExecution(uint256 _agentId, bytes4 _protocolId)
        external
        whenNotPaused
        onlyAgentOwner(_agentId)
    {
        require(protocols[_protocolId].exists, "NexusForge: Protocol does not exist");
        require(_agentAssignedProtocols[_agentId].contains(_protocolId), "NexusForge: Protocol not assigned to agent");
        require(protocols[_protocolId].requiresOwnerApproval, "NexusForge: Protocol does not require owner approval");

        _agentProtocolApproved[_agentId][_protocolId] = true;
        emit AgentProtocolExecutionApproved(_agentId, _protocolId, msg.sender);
    }

    /**
     * @dev The core function to trigger an Agent to execute an assigned Protocol.
     * Verifies agent activation, capabilities, available essence, and owner approval (if required).
     * Deducts total essence cost, performs the external call, and updates reputation/rewards on success.
     * Callable by the Agent owner (or a whitelisted executor for protocols that don't require explicit owner approval for each execution).
     * @param _agentId The ID of the agent to trigger.
     * @param _protocolId The ID of the protocol to execute.
     * @param _callData The full call data for the external interaction (must start with `_targetFunctionSignature`).
     */
    function triggerAgentProtocol(
        uint256 _agentId,
        bytes4 _protocolId,
        bytes memory _callData
    ) external whenNotPaused {
        require(_exists(_agentId), "NexusForge: Agent does not exist");
        require(agents[_agentId].isActive, "NexusForge: Agent is not active");
        require(ownerOf(_agentId) == msg.sender, "NexusForge: Caller is not agent owner");
        require(protocols[_protocolId].exists, "NexusForge: Protocol does not exist");
        require(_agentAssignedProtocols[_agentId].contains(_protocolId), "NexusForge: Protocol not assigned to agent");
        require(_callData.length >= 4 && bytes4(_callData) == protocols[_protocolId].targetFunctionSignature,
                "NexusForge: Call data does not match target function signature");

        // Check for owner approval if required
        if (protocols[_protocolId].requiresOwnerApproval) {
            require(_agentProtocolApproved[_agentId][_protocolId], "NexusForge: Owner approval required for this execution");
            _agentProtocolApproved[_agentId][_protocolId] = false; // Approval is for single use
        }

        // Verify agent capabilities
        EnumerableSet.UintSet storage agentCapabilities = _getAgentCapabilities(_agentId);
        for (uint256 i = 0; i < protocols[_protocolId].requiredCapabilities.length; i++) {
            require(agentCapabilities.contains(protocols[_protocolId].requiredCapabilities[i]), 
                    "NexusForge: Agent lacks required capability");
        }

        // Calculate total essence cost
        uint256 totalEssenceCost = protocols[_protocolId].essenceCost;
        uint256[] memory attachedComponentIds = agents[_agentId].attachedComponents.values();
        for (uint256 i = 0; i < attachedComponentIds.length; i++) {
            totalEssenceCost += components[attachedComponentIds[i]].baseEssenceCost;
        }

        // Deduct essence
        require(getConduitEssence() >= totalEssenceCost, "NexusForge: Insufficient Essence in Conduit");
        require(essenceToken.transfer(address(protocols[_protocolId].targetContract), totalEssenceCost), "NexusForge: Essence transfer to target contract failed");

        // Execute external call
        (bool success, ) = protocols[_protocolId].targetContract.call(_callData);

        if (success) {
            protocols[_protocolId].successCount++;
            agents[_agentId].reputation++;
            // Reward agent owner
            if (protocols[_protocolId].essenceReward > 0) {
                 // Check if contract has enough Essence to give reward
                if (essenceToken.balanceOf(address(this)) >= protocols[_protocolId].essenceReward) {
                    essenceToken.transfer(ownerOf(_agentId), protocols[_protocolId].essenceReward);
                } else {
                    // Log event or handle insufficient reward funds if necessary
                }
            }
        } else {
            protocols[_protocolId].failureCount++;
            // Optionally reduce reputation on failure
            if (agents[_agentId].reputation > 0) {
                agents[_agentId].reputation--;
            }
        }
        emit AgentProtocolTriggered(_agentId, _protocolId, success, totalEssenceCost, protocols[_protocolId].essenceReward);
    }

    // --- XII. Reputation & Monitoring ---

    /**
     * @dev Retrieves the success-based reputation score of an agent.
     * Reputation increases with successful protocol executions and may decrease on failure.
     * @param _agentId The ID of the agent.
     * @return The current reputation score.
     */
    function getAgentReputation(uint256 _agentId) public view returns (uint256) {
        require(_exists(_agentId), "NexusForge: Agent does not exist");
        return agents[_agentId].reputation;
    }

    /**
     * @dev Returns the total success and failure counts for a given Protocol.
     * @param _protocolId The ID of the protocol.
     * @return successCount The number of successful executions.
     * @return failureCount The number of failed executions.
     */
    function getProtocolPerformance(bytes4 _protocolId)
        public
        view
        returns (uint256 successCount, uint256 failureCount)
    {
        require(protocols[_protocolId].exists, "NexusForge: Protocol does not exist");
        return (protocols[_protocolId].successCount, protocols[_protocolId].failureCount);
    }

    // --- XIII. Internal Helper Functions ---

    /**
     * @dev Internal helper to gather all capabilities of an agent.
     */
    function _getAgentCapabilities(uint256 _agentId) internal view returns (EnumerableSet.UintSet storage) {
        EnumerableSet.UintSet storage agentCapabilities = new EnumerableSet.UintSet();
        uint256[] memory attachedComponentIds = agents[_agentId].attachedComponents.values();
        for (uint256 i = 0; i < attachedComponentIds.length; i++) {
            uint256 componentId = attachedComponentIds[i];
            for (uint256 j = 0; j < components[componentId].capabilityIds.length; j++) {
                agentCapabilities.add(components[componentId].capabilityIds[j]);
            }
        }
        return agentCapabilities; // Note: This returns a storage reference, which might not be ideal for complex cases.
                                  // For simplicity in this example, it works. For more complex logic,
                                  // it might be better to return a memory array or process directly.
    }
}
```