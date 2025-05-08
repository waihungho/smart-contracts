Okay, let's design a smart contract based on a concept that involves dynamic state, time-based interactions, resource management, and decentralized agent control, moving beyond typical token or simple protocol patterns.

We'll create a "Chronos Ecology Simulator" – a simplified on-chain world where distinct "Agent" entities live, consume "Resources," age, and interact, with time progressing via simulation cycles triggered by users or authorized entities.

**Concept:** Users own Agents. Agents have state (energy, age, species). Global Resources exist in the contract. Users trigger actions for their agents (feeding, reproducing, etc.), which consume resources and energy. A global simulation cycle periodically affects all agents (e.g., energy decay) and resources (e.g., spawning). The system parameters can be adjusted.

This allows for emergent behavior, resource economics, and user interaction that drives the simulation forward. It's distinct from standard NFTs, DeFi protocols, or DAOs.

---

**Chronos Ecology Simulator Smart Contract**

**Outline:**

1.  **State Variables:** Define core data structures for Agents, Resources, Environment Configuration, and mappings for ownership and state.
2.  **Enums:** Define types for Agent Species and Resource Types.
3.  **Structs:** Define the data structures for `Agent`, `SpeciesParameters`, `EnvironmentConfig`.
4.  **Events:** Define events to signal key state changes and actions.
5.  **Modifiers:** Define access control modifiers (`onlyOwner`, `onlyAuthorizedController`).
6.  **Admin & Setup Functions:** Functions to initialize and configure the simulator (owner only).
7.  **Agent Management Functions (User/Owner):** Functions for users to interact with their owned agents (create, transfer, retire, view).
8.  **Simulation & Interaction Functions (User/Controller):** Functions to advance agent state, trigger global cycles, and perform agent actions.
9.  **Resource Management (Internal/View):** Internal helpers for resource logic and view functions to check resource state.
10. **Query Functions (View):** Functions to retrieve various pieces of information about the simulator state.

**Function Summary:**

*   `constructor()`: Initializes the contract owner and basic environment config.
*   `setEnvironmentConfig(EnvironmentConfig memory _config)`: Sets global simulation parameters (Owner only).
*   `setSpeciesParameters(uint256 _speciesType, SpeciesParameters memory _params)`: Sets parameters for a specific species type (Owner only).
*   `addAuthorizedController(address _controller)`: Adds an address authorized to trigger global cycles (Owner only).
*   `removeAuthorizedController(address _controller)`: Removes an authorized controller (Owner only).
*   `pauseSimulation()`: Halts the global simulation cycle progression (Owner only).
*   `unpauseSimulation()`: Resumes the global simulation cycle progression (Owner only).
*   `createAgent(uint256 _speciesType)`: Creates a new agent of a specified type for the caller. Costs defined resources/energy.
*   `triggerAgentSimulationStep(uint256 _agentId)`: Advances the state (age, energy decay) for a single agent based on the time passed since its last simulation cycle (Agent Owner only).
*   `triggerGlobalSimulationCycle()`: Advances the global simulation cycle, potentially spawning resources and triggering global effects (Authorized Controller only).
*   `agentPerformAction_Feed(uint256 _agentId, ResourceType _resourceType, uint256 _amount)`: Allows an agent owner to use an agent to consume a specific resource type, increasing the agent's energy (Agent Owner only).
*   `agentPerformAction_Reproduce(uint256 _agentId, uint256 _newSpeciesType)`: Allows an agent to reproduce, creating a new agent. Costs energy/resources and has cooldowns/requirements defined by species parameters (Agent Owner only).
*   `agentPerformAction_Explore(uint256 _agentId)`: A placeholder action, costs energy and potentially yields a minor benefit or triggers a small state change for the agent (Agent Owner only).
*   `transferAgent(address _to, uint256 _agentId)`: Transfers ownership of an agent (Current Agent Owner only).
*   `retireAgent(uint256 _agentId)`: Deactivates/effectively burns an agent owned by the caller.
*   `getAgentDetails(uint256 _agentId)`: Retrieves the full state details of an agent (View).
*   `getGlobalResources(ResourceType _resourceType)`: Retrieves the current global amount of a specific resource type (View).
*   `getEnvironmentConfig()`: Retrieves the current global environment configuration (View).
*   `getSpeciesParameters(uint256 _speciesType)`: Retrieves the parameters for a specific species type (View).
*   `getAgentCount()`: Retrieves the total number of agents ever created (View).
*   `getActiveAgentCount()`: Retrieves the number of currently active agents (View).
*   `getSimulationStatus()`: Retrieves the current global simulation cycle and pause status (View).
*   `getAgentOwner(uint256 _agentId)`: Retrieves the owner address of a specific agent (View).
*   `listOwnedAgents(address _owner)`: Retrieves the list of agent IDs owned by an address (View - note: iterating arrays in view functions can be gas-intensive for large lists).
*   `_spawnGlobalResources()`: Internal function to add resources based on the environment config.
*   `_decayGlobalResources()`: Internal function to reduce resources based on the environment config.
*   `_consumeGlobalResource(ResourceType _resourceType, uint256 _amount)`: Internal function to deduct resources globally.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Chronos Ecology Simulator
 * @dev A dynamic, time-based simulation contract involving Agents, Resources, and environmental factors.
 * Users own Agents and trigger their actions and individual simulation steps.
 * Authorized controllers trigger global simulation cycles affecting resources and all agents.
 * State evolves based on time, resource availability, and agent actions.
 *
 * Outline:
 * 1. State Variables: Core data structures for Agents, Resources, Environment Configuration, and mappings.
 * 2. Enums: Agent Species Types, Resource Types.
 * 3. Structs: Agent, SpeciesParameters, EnvironmentConfig.
 * 4. Events: Signal key state changes.
 * 5. Modifiers: Access control.
 * 6. Admin & Setup Functions: Configure the simulation.
 * 7. Agent Management Functions (User/Owner): Create, transfer, retire agents.
 * 8. Simulation & Interaction Functions (User/Controller): Advance time, perform agent actions.
 * 9. Resource Management (Internal/View): Handle global resources.
 * 10. Query Functions (View): Retrieve simulation state information.
 */
contract ChronosEcologySimulator {

    // --- 1. State Variables ---
    address private immutable i_owner; // Contract deployer
    mapping(address => bool) private s_authorizedControllers; // Addresses allowed to trigger global cycle
    bool private s_simulationPaused = false; // Global pause flag

    uint256 private s_nextAgentId = 1; // Counter for unique agent IDs
    uint256 private s_activeAgentCount = 0; // Count of active agents

    // Agent State: agentId => Agent struct
    mapping(uint256 => Agent) private s_agents;
    // Agent Ownership: agentId => owner address
    mapping(uint256 => address) private s_agentOwner;
    // Agents owned by an address: owner address => list of agent IDs
    mapping(address => uint256[]) private s_ownedAgents;
    // Index of agent in the ownedAgents array: agentId => index
    mapping(uint256 => uint256) private s_ownedAgentIndex;


    // Global Resources: resourceType => amount
    mapping(ResourceType => uint256) private s_globalResources;

    // Configuration: Environment and Species parameters
    EnvironmentConfig private s_environmentConfig;
    mapping(uint256 => SpeciesParameters) private s_speciesParameters; // speciesType => parameters

    // --- 2. Enums ---
    enum ResourceType { Nutrient, EnergyShard, Water } // Example resource types
    enum AgentStatus { Active, Retired } // Agent status

    // --- 3. Structs ---
    struct Agent {
        uint256 id;
        uint256 speciesType; // Links to s_speciesParameters
        AgentStatus status;
        uint256 energy;
        uint256 age; // Incremented by simulation steps
        uint256 lastSimulatedCycle; // Last global cycle this agent was processed against for decay/age
        string name; // Cosmetic name
    }

    struct SpeciesParameters {
        uint256 maxAge; // Max cycles the agent can live
        uint256 baseEnergyDecayPerCycle; // Energy lost per simulated cycle
        uint256 reproductionEnergyCost; // Energy cost to reproduce
        uint256 reproductionCooldownCycles; // Cycles between reproductions
        uint256 minEnergyToReproduce; // Minimum energy required to reproduce
        mapping(ResourceType => uint256) feedingEnergyGain; // How much energy feeding a resource grants
        mapping(ResourceType => uint256) feedingResourceCost; // Resource amount consumed per feed action (e.g., 1 unit)
    }

    struct EnvironmentConfig {
        uint256 currentCycle; // Global simulation cycle counter
        uint256 globalResourceSpawnRate; // Amount of resources spawned per global cycle (example, could be per type)
        uint256 agentEnergyDecayRate; // Global decay rate applied on top of species decay (percentage, e.g., 100 = 1x)
        uint256 actionBaseCost; // Base energy cost for any specific agent action
        uint256 agentCreationResourceCost; // Resource cost to create a new agent
        ResourceType agentCreationResourceType; // Type of resource needed for creation
    }

    // --- 4. Events ---
    event AgentCreated(uint256 indexed agentId, address indexed owner, uint256 speciesType, uint256 initialEnergy);
    event AgentTransferred(uint256 indexed agentId, address indexed from, address indexed to);
    event AgentRetired(uint256 indexed agentId, address indexed owner);
    event GlobalCycleAdvanced(uint256 newCycle, uint256 resourcesSpawnedTotal);
    event AgentSimulationStep(uint256 indexed agentId, uint256 cyclesPassed, uint256 energyLost, uint256 newAge);
    event AgentActionPerformed(uint256 indexed agentId, string actionType, uint256 energyCost);
    event ResourceSpawned(ResourceType indexed resourceType, uint256 amount);
    event ResourceConsumed(ResourceType indexed resourceType, uint256 amount);
    event EnvironmentConfigUpdated(uint256 newResourceSpawnRate, uint256 newAgentEnergyDecayRate);
    event SpeciesParametersUpdated(uint256 speciesType, uint256 maxAge);
    event AuthorizedControllerAdded(address indexed controller);
    event AuthorizedControllerRemoved(address indexed controller);
    event SimulationPaused(uint256 currentCycle);
    event SimulationUnpaused(uint256 currentCycle);


    // --- 5. Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == i_owner, "Not owner");
        _;
    }

    modifier onlyAuthorizedController() {
        require(msg.sender == i_owner || s_authorizedControllers[msg.sender], "Not authorized controller");
        _;
    }

    modifier whenNotPaused() {
        require(!s_simulationPaused, "Simulation is paused");
        _;
    }

    // --- 6. Admin & Setup Functions ---

    /**
     * @dev Initializes the contract with the deployer as owner and sets initial config.
     */
    constructor() {
        i_owner = msg.sender;
        // Set some initial default configuration
        s_environmentConfig = EnvironmentConfig({
            currentCycle: 0,
            globalResourceSpawnRate: 100, // Example value
            agentEnergyDecayRate: 100, // 100% of species decay
            actionBaseCost: 10, // Base energy cost per action
            agentCreationResourceCost: 50, // Cost to create an agent
            agentCreationResourceType: ResourceType.Nutrient // Resource type for creation
        });

        // Set some default species parameters (example species 1)
        s_speciesParameters[1] = SpeciesParameters({
            maxAge: 1000,
            baseEnergyDecayPerCycle: 1,
            reproductionEnergyCost: 50,
            reproductionCooldownCycles: 10,
            minEnergyToReproduce: 70,
            feedingEnergyGain: new mapping(ResourceType => uint256)(),
            feedingResourceCost: new mapping(ResourceType => uint256)()
        });
        s_speciesParameters[1].feedingEnergyGain[ResourceType.Nutrient] = 20;
        s_speciesParameters[1].feedingResourceCost[ResourceType.Nutrient] = 1;

         // Set some default species parameters (example species 2)
        s_speciesParameters[2] = SpeciesParameters({
            maxAge: 800,
            baseEnergyDecayPerCycle: 2,
            reproductionEnergyCost: 80,
            reproductionCooldownCycles: 8,
            minEnergyToReproduce: 100,
            feedingEnergyGain: new mapping(ResourceType => uint256)(),
            feedingResourceCost: new mapping(ResourceType => uint256)()
        });
        s_speciesParameters[2].feedingEnergyGain[ResourceType.EnergyShard] = 30;
        s_speciesParameters[2].feedingResourceCost[ResourceType.EnergyShard] = 1;

        // Spawn some initial resources
        s_globalResources[ResourceType.Nutrient] = 500;
        s_globalResources[ResourceType.EnergyShard] = 200;
        s_globalResources[ResourceType.Water] = 300;

        emit EnvironmentConfigUpdated(s_environmentConfig.globalResourceSpawnRate, s_environmentConfig.agentEnergyDecayRate);
        emit SpeciesParametersUpdated(1, s_speciesParameters[1].maxAge);
         emit SpeciesParametersUpdated(2, s_speciesParameters[2].maxAge);
    }

    /**
     * @dev Sets the global environment configuration parameters.
     * @param _config The new EnvironmentConfig struct.
     */
    function setEnvironmentConfig(EnvironmentConfig memory _config) external onlyOwner {
        s_environmentConfig = _config;
        emit EnvironmentConfigUpdated(_config.globalResourceSpawnRate, _config.agentEnergyDecayRate);
    }

    /**
     * @dev Sets the parameters for a specific agent species type.
     * @param _speciesType The species type ID.
     * @param _params The SpeciesParameters struct for the species.
     */
    function setSpeciesParameters(uint256 _speciesType, SpeciesParameters memory _params) external onlyOwner {
         // Basic validation
        require(_speciesType > 0, "Species type must be > 0");
        require(_params.maxAge > 0, "Max age must be > 0");
        require(_params.baseEnergyDecayPerCycle < 1000, "Decay rate too high"); // Sanity check

        s_speciesParameters[_speciesType] = _params;
        emit SpeciesParametersUpdated(_speciesType, _params.maxAge);
    }

    /**
     * @dev Adds an address that is authorized to trigger global simulation cycles.
     * @param _controller The address to authorize.
     */
    function addAuthorizedController(address _controller) external onlyOwner {
        require(_controller != address(0), "Invalid address");
        s_authorizedControllers[_controller] = true;
        emit AuthorizedControllerAdded(_controller);
    }

    /**
     * @dev Removes an address from the authorized controllers list.
     * @param _controller The address to remove authorization from.
     */
    function removeAuthorizedController(address _controller) external onlyOwner {
        require(_controller != address(0), "Invalid address");
        s_authorizedControllers[_controller] = false;
        emit AuthorizedControllerRemoved(_controller);
    }

    /**
     * @dev Pauses the global simulation cycle progression.
     * Agent-specific actions can still be performed.
     */
    function pauseSimulation() external onlyOwner {
        require(!s_simulationPaused, "Simulation is already paused");
        s_simulationPaused = true;
        emit SimulationPaused(s_environmentConfig.currentCycle);
    }

    /**
     * @dev Unpauses the global simulation cycle progression.
     */
    function unpauseSimulation() external onlyOwner {
        require(s_simulationPaused, "Simulation is not paused");
        s_simulationPaused = false;
        emit SimulationUnpaused(s_environmentConfig.currentCycle);
    }

    // --- 7. Agent Management Functions (User/Owner) ---

    /**
     * @dev Creates a new agent of a specific species type for the caller.
     * Requires payment in resources as defined by environment config.
     * @param _speciesType The species type of the agent to create.
     */
    function createAgent(uint256 _speciesType) external whenNotPaused {
        require(s_speciesParameters[_speciesType].maxAge > 0, "Invalid species type"); // Species must have defined parameters
        require(s_globalResources[s_environmentConfig.agentCreationResourceType] >= s_environmentConfig.agentCreationResourceCost, "Insufficient creation resources");

        // Consume creation resources
        _consumeGlobalResource(s_environmentConfig.agentCreationResourceType, s_environmentConfig.agentCreationResourceCost);

        uint256 agentId = s_nextAgentId++;
        s_activeAgentCount++;

        s_agents[agentId] = Agent({
            id: agentId,
            speciesType: _speciesType,
            status: AgentStatus.Active,
            energy: 100, // Starting energy
            age: 0,
            lastSimulatedCycle: s_environmentConfig.currentCycle,
            name: "" // Default empty name
        });

        _assignAgentOwnership(agentId, msg.sender);

        emit AgentCreated(agentId, msg.sender, _speciesType, s_agents[agentId].energy);
    }

    /**
     * @dev Advances the state (age, energy decay) for a single agent.
     * This function allows users to keep their agents 'up-to-date' with time.
     * @param _agentId The ID of the agent to simulate.
     */
    function triggerAgentSimulationStep(uint256 _agentId) external whenNotPaused {
        Agent storage agent = s_agents[_agentId];
        require(agent.status == AgentStatus.Active, "Agent is not active");
        require(s_agentOwner[_agentId] == msg.sender, "Not agent owner");
        require(agent.lastSimulatedCycle < s_environmentConfig.currentCycle, "Agent already simulated for current cycle");

        uint256 cyclesPassed = s_environmentConfig.currentCycle - agent.lastSimulatedCycle;
        SpeciesParameters storage speciesParams = s_speciesParameters[agent.speciesType];

        uint256 energyDecay = cyclesPassed * (speciesParams.baseEnergyDecayPerCycle * s_environmentConfig.agentEnergyDecayRate / 100);
        uint256 energyLost = 0;

        if (agent.energy > energyDecay) {
            agent.energy -= energyDecay;
            energyLost = energyDecay;
        } else {
            energyLost = agent.energy;
            agent.energy = 0;
            // Optionally, retire agent if energy reaches 0? Or just make it inactive/dormant.
            // Let's make it lose all energy, still active but unable to perform actions.
        }

        agent.age += cyclesPassed;
        agent.lastSimulatedCycle = s_environmentConfig.currentCycle;

        // Check for aging out
        if (agent.age >= speciesParams.maxAge) {
            _retireAgent(_agentId); // Internal call to retire
            return; // Exit as agent is now retired
        }

        emit AgentSimulationStep(_agentId, cyclesPassed, energyLost, agent.age);
    }


    /**
     * @dev Transfers ownership of an agent to another address.
     * @param _to The recipient address.
     * @param _agentId The ID of the agent to transfer.
     */
    function transferAgent(address _to, uint256 _agentId) external {
        require(s_agents[_agentId].status == AgentStatus.Active, "Agent is not active");
        require(s_agentOwner[_agentId] == msg.sender, "Not agent owner");
        require(_to != address(0), "Invalid recipient address");
        require(_to != msg.sender, "Cannot transfer to self");

        // Remove from old owner's list
        _removeAgentFromOwnedList(msg.sender, _agentId);

        // Assign to new owner
        _assignAgentOwnership(_agentId, _to);

        emit AgentTransferred(_agentId, msg.sender, _to);
    }

     /**
     * @dev Allows the agent owner to set a cosmetic name for their agent.
     * @param _agentId The ID of the agent.
     * @param _name The new name for the agent. Max length 32 bytes.
     */
    function renameAgent(uint256 _agentId, string calldata _name) external {
         require(s_agents[_agentId].status == AgentStatus.Active, "Agent is not active");
         require(s_agentOwner[_agentId] == msg.sender, "Not agent owner");
         bytes memory nameBytes = bytes(_name);
         require(nameBytes.length <= 32, "Name too long"); // Simple length restriction

         s_agents[_agentId].name = _name;
         // No specific event for rename, could add one if needed.
    }


    /**
     * @dev Retires an agent owned by the caller. The agent becomes inactive.
     * @param _agentId The ID of the agent to retire.
     */
    function retireAgent(uint256 _agentId) external {
        require(s_agents[_agentId].status == AgentStatus.Active, "Agent is already retired");
        require(s_agentOwner[_agentId] == msg.sender, "Not agent owner");

        _retireAgent(_agentId); // Internal call
    }

    /**
     * @dev Internal function to mark an agent as retired.
     * @param _agentId The ID of the agent to retire.
     */
    function _retireAgent(uint256 _agentId) internal {
        Agent storage agent = s_agents[_agentId];
        agent.status = AgentStatus.Retired;
        agent.energy = 0; // Agents lose energy/resources upon retirement

        // Remove from owner's list
        _removeAgentFromOwnedList(s_agentOwner[_agentId], _agentId);

        s_activeAgentCount--;

        // Note: We don't delete the Agent struct or ownership mapping entry
        // to maintain historical data and prevent ID reuse issues.
        // The status check is used everywhere.

        emit AgentRetired(_agentId, s_agentOwner[_agentId]);
    }

    // --- 8. Simulation & Interaction Functions (User/Controller) ---

     /**
     * @dev Advances the global simulation cycle counter and triggers global effects.
     * Can only be called by the owner or an authorized controller.
     */
    function triggerGlobalSimulationCycle() external onlyAuthorizedController whenNotPaused {
        s_environmentConfig.currentCycle++;
        _spawnGlobalResources();
        _decayGlobalResources(); // Example: Resources decay slightly each cycle

        // Note: Agent aging and decay for individual agents is handled when
        // triggerAgentSimulationStep is called, not here globally. This saves gas.
        // The global cycle primarily progresses time for resources and global events.

        emit GlobalCycleAdvanced(s_environmentConfig.currentCycle, s_environmentConfig.globalResourceSpawnRate);
    }

    /**
     * @dev Allows an agent to consume a specific resource type from the global pool.
     * @param _agentId The ID of the agent performing the action.
     * @param _resourceType The type of resource to consume.
     * @param _amount The amount of resource to consume (must match species cost).
     */
    function agentPerformAction_Feed(uint256 _agentId, ResourceType _resourceType, uint256 _amount) external whenNotPaused {
        Agent storage agent = s_agents[_agentId];
        require(agent.status == AgentStatus.Active, "Agent is not active");
        require(s_agentOwner[_agentId] == msg.sender, "Not agent owner");

        // Ensure agent is up-to-date with simulation before action
        if (agent.lastSimulatedCycle < s_environmentConfig.currentCycle) {
             triggerAgentSimulationStep(_agentId);
             // Re-fetch agent storage reference as state might have changed
             agent = s_agents[_agentId];
             require(agent.status == AgentStatus.Active, "Agent became inactive after simulation step");
        }


        SpeciesParameters storage speciesParams = s_speciesParameters[agent.speciesType];
        require(agent.energy >= s_environmentConfig.actionBaseCost, "Insufficient energy for action base cost");
        require(speciesParams.feedingResourceCost[_resourceType] > 0, "Agent species cannot consume this resource type");
        require(_amount == speciesParams.feedingResourceCost[_resourceType], "Amount must match species cost per feed"); // Simple model: consume exactly what species needs per action
        require(s_globalResources[_resourceType] >= _amount, "Insufficient global resources");

        uint256 totalActionCost = s_environmentConfig.actionBaseCost;
        // Add any species-specific action cost here if needed

        require(agent.energy >= totalActionCost, "Insufficient energy for action");

        // Consume energy
        agent.energy -= totalActionCost;

        // Consume global resources
        _consumeGlobalResource(_resourceType, _amount);

        // Gain energy from feeding
        uint256 energyGained = _amount * speciesParams.feedingEnergyGain[_resourceType]; // Gain per unit consumed
        agent.energy += energyGained;

        emit AgentActionPerformed(_agentId, "Feed", totalActionCost);
        // Could add ResourceConsumed event here too, but _consumeGlobalResource also emits it
    }

     /**
     * @dev Allows an agent to reproduce, creating a new agent.
     * @param _agentId The ID of the agent performing the action.
     * @param _newSpeciesType The species type for the new offspring agent.
     */
    function agentPerformAction_Reproduce(uint256 _agentId, uint256 _newSpeciesType) external whenNotPaused {
        Agent storage parentAgent = s_agents[_agentId];
        require(parentAgent.status == AgentStatus.Active, "Agent is not active");
        require(s_agentOwner[_agentId] == msg.sender, "Not agent owner");
        require(s_speciesParameters[_newSpeciesType].maxAge > 0, "Invalid offspring species type"); // Offspring species must exist

        // Ensure agent is up-to-date with simulation before action
         if (parentAgent.lastSimulatedCycle < s_environmentConfig.currentCycle) {
             triggerAgentSimulationStep(_agentId);
             // Re-fetch agent storage reference
             parentAgent = s_agents[_agentId];
             require(parentAgent.status == AgentStatus.Active, "Agent became inactive after simulation step");
        }

        SpeciesParameters storage speciesParams = s_speciesParameters[parentAgent.speciesType];
        uint256 totalActionCost = s_environmentConfig.actionBaseCost + speciesParams.reproductionEnergyCost;

        require(parentAgent.energy >= totalActionCost, "Insufficient energy to reproduce");
        require(parentAgent.energy >= speciesParams.minEnergyToReproduce, "Not enough energy to meet reproduction threshold");
        // Could add cooldown logic here based on last reproduction cycle

        // Consume energy
        parentAgent.energy -= totalActionCost;

        // Create new agent (offspring) - uses the same creation logic
        require(s_globalResources[s_environmentConfig.agentCreationResourceType] >= s_environmentConfig.agentCreationResourceCost, "Insufficient creation resources for offspring");
        _consumeGlobalResource(s_environmentConfig.agentCreationResourceType, s_environmentConfig.agentCreationResourceCost);

        uint256 newAgentId = s_nextAgentId++;
        s_activeAgentCount++;

        s_agents[newAgentId] = Agent({
            id: newAgentId,
            speciesType: _newSpeciesType, // Can reproduce a different species
            status: AgentStatus.Active,
            energy: 50, // Starting energy for offspring (example)
            age: 0,
            lastSimulatedCycle: s_environmentConfig.currentCycle,
             name: ""
        });

        _assignAgentOwnership(newAgentId, msg.sender); // Offspring owned by parent owner

        emit AgentActionPerformed(_agentId, "Reproduce", totalActionCost);
        emit AgentCreated(newAgentId, msg.sender, _newSpeciesType, s_agents[newAgentId].energy);

        // Could add a 'lastReproducedCycle' to the Agent struct for cooldown logic
    }

     /**
     * @dev A placeholder action - agent expends energy to 'explore'.
     * Could potentially find resources or change location in a more complex simulation.
     * @param _agentId The ID of the agent performing the action.
     */
    function agentPerformAction_Explore(uint256 _agentId) external whenNotPaused {
        Agent storage agent = s_agents[_agentId];
        require(agent.status == AgentStatus.Active, "Agent is not active");
        require(s_agentOwner[_agentId] == msg.sender, "Not agent owner");

        // Ensure agent is up-to-date with simulation before action
         if (agent.lastSimulatedCycle < s_environmentConfig.currentCycle) {
             triggerAgentSimulationStep(_agentId);
             // Re-fetch agent storage reference
             agent = s_agents[_agentId];
             require(agent.status == AgentStatus.Active, "Agent became inactive after simulation step");
        }

        uint256 totalActionCost = s_environmentConfig.actionBaseCost;
        // Could add species-specific explore cost

        require(agent.energy >= totalActionCost, "Insufficient energy for action");

        // Consume energy
        agent.energy -= totalActionCost;

        // Placeholder for exploration effect - maybe a small chance to find resources or gain a minor buff?
        // For simplicity in this example, it just costs energy.

        emit AgentActionPerformed(_agentId, "Explore", totalActionCost);
    }


    // --- 9. Resource Management (Internal/View) ---

    /**
     * @dev Internal function to spawn resources based on environment config.
     * Called by triggerGlobalSimulationCycle.
     */
    function _spawnGlobalResources() internal {
        // Simple model: spawn same amount of each resource type
        for (uint i = 0; i < uint(type(ResourceType).max); i++) {
             ResourceType resourceType = ResourceType(i);
             s_globalResources[resourceType] += s_environmentConfig.globalResourceSpawnRate;
             emit ResourceSpawned(resourceType, s_environmentConfig.globalResourceSpawnRate);
        }
    }

     /**
     * @dev Internal function to decay global resources.
     * Called by triggerGlobalSimulationCycle.
     */
    function _decayGlobalResources() internal {
        // Simple model: remove a small percentage of each resource type
         uint256 decayPercentage = 1; // Example: 1% decay per cycle
        for (uint i = 0; i < uint(type(ResourceType).max); i++) {
             ResourceType resourceType = ResourceType(i);
             uint256 currentAmount = s_globalResources[resourceType];
             uint256 decayAmount = currentAmount * decayPercentage / 100;
             if (decayAmount > 0) {
                s_globalResources[resourceType] -= decayAmount;
                // No specific decay event for simplicity
             }
        }
    }


     /**
     * @dev Internal function to consume global resources.
     * Called by agent actions or agent creation.
     * @param _resourceType The type of resource to consume.
     * @param _amount The amount to consume.
     */
    function _consumeGlobalResource(ResourceType _resourceType, uint256 _amount) internal {
        require(s_globalResources[_resourceType] >= _amount, "Insufficient global resources");
        s_globalResources[_resourceType] -= _amount;
        emit ResourceConsumed(_resourceType, _amount);
    }


    // --- 10. Query Functions (View) ---

    /**
     * @dev Gets the full details of a specific agent.
     * @param _agentId The ID of the agent.
     * @return Agent struct details.
     */
    function getAgentDetails(uint256 _agentId) external view returns (Agent memory) {
        require(s_agents[_agentId].id != 0, "Agent does not exist"); // Check if agent struct is non-zero (id is first field)
        return s_agents[_agentId];
    }

    /**
     * @dev Gets the current global amount of a specific resource type.
     * @param _resourceType The type of resource.
     * @return The current amount.
     */
    function getGlobalResources(ResourceType _resourceType) external view returns (uint256) {
        return s_globalResources[_resourceType];
    }

    /**
     * @dev Gets the current global environment configuration.
     * @return EnvironmentConfig struct.
     */
    function getEnvironmentConfig() external view returns (EnvironmentConfig memory) {
        return s_environmentConfig;
    }

    /**
     * @dev Gets the parameters for a specific species type.
     * @param _speciesType The species type ID.
     * @return SpeciesParameters struct.
     */
    function getSpeciesParameters(uint256 _speciesType) external view returns (SpeciesParameters memory) {
         require(s_speciesParameters[_speciesType].maxAge > 0, "Species parameters not set"); // Check if parameters exist
        return s_speciesParameters[_speciesType];
    }

    /**
     * @dev Gets the total number of agents ever created.
     * @return The total agent count.
     */
    function getAgentCount() external view returns (uint256) {
        return s_nextAgentId - 1; // nextId is one more than count
    }

    /**
     * @dev Gets the number of currently active agents.
     * @return The count of active agents.
     */
    function getActiveAgentCount() external view returns (uint256) {
        return s_activeAgentCount;
    }

    /**
     * @dev Gets the current global simulation cycle and pause status.
     * @return currentCycle The current global cycle number.
     * @return isPaused True if simulation is paused, false otherwise.
     */
    function getSimulationStatus() external view returns (uint256 currentCycle, bool isPaused) {
        return (s_environmentConfig.currentCycle, s_simulationPaused);
    }

    /**
     * @dev Gets the owner address of a specific agent.
     * @param _agentId The ID of the agent.
     * @return The owner address.
     */
    function getAgentOwner(uint256 _agentId) external view returns (address) {
        require(s_agents[_agentId].id != 0, "Agent does not exist");
        return s_agentOwner[_agentId];
    }

    /**
     * @dev Gets the list of agent IDs owned by a specific address.
     * @param _owner The owner address.
     * @return An array of agent IDs.
     */
    function listOwnedAgents(address _owner) external view returns (uint256[] memory) {
        return s_ownedAgents[_owner];
    }

    /**
     * @dev Checks if an address is an authorized controller.
     * @param _controller The address to check.
     * @return True if authorized, false otherwise.
     */
    function isAuthorizedController(address _controller) external view returns (bool) {
        return s_authorizedControllers[_controller];
    }

     /**
     * @dev Gets the contract owner address.
     * @return The owner address.
     */
    function owner() external view returns (address) {
        return i_owner;
    }


    // --- Internal Helper Functions for Mappings ---
    // These helpers manage the s_ownedAgents dynamic array and s_ownedAgentIndex mapping.
    // Note: Removing from a dynamic array in Solidity is O(N) in the worst case
    // if the item is not the last element. This implementation swaps with the last element
    // to achieve O(1) removal, but requires updating the index mapping for the swapped element.

    /**
     * @dev Internal function to assign ownership of an agent and update mappings.
     * @param _agentId The ID of the agent.
     * @param _to The recipient address.
     */
    function _assignAgentOwnership(uint256 _agentId, address _to) internal {
        s_agentOwner[_agentId] = _to;
        uint256[] storage ownedAgents = s_ownedAgents[_to];
        s_ownedAgentIndex[_agentId] = ownedAgents.length;
        ownedAgents.push(_agentId);
    }

    /**
     * @dev Internal function to remove an agent from an owner's list and update mappings.
     * Uses swap-and-pop for O(1) complexity.
     * @param _from The previous owner address.
     * @param _agentId The ID of the agent.
     */
    function _removeAgentFromOwnedList(address _from, uint256 _agentId) internal {
        uint256[] storage ownedAgents = s_ownedAgents[_from];
        uint256 index = s_ownedAgentIndex[_agentId];

        // If the agent is not the last one in the array, swap it with the last one
        if (index < ownedAgents.length - 1) {
            uint256 lastAgentId = ownedAgents[ownedAgents.length - 1];
            ownedAgents[index] = lastAgentId;
            s_ownedAgentIndex[lastAgentId] = index; // Update the index mapping for the swapped agent
        }

        // Remove the last element (which is now either the target agent or the one we swapped)
        ownedAgents.pop();

        // Clean up the index mapping for the removed agent
        delete s_ownedAgentIndex[_agentId];
    }
}
```