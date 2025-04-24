Okay, let's create an interesting, advanced, and creative smart contract. We'll design a contract that manages **Programmable On-Chain Agents** within a simulated ecosystem. These agents are unique NFTs (ERC721-like functionality implemented manually to avoid direct open-source duplication) that can interact with each other, consume and produce a specific resource token (ERC20-like interaction), evolve based on rules, and operate within a global simulation epoch.

This combines concepts of dynamic NFTs, on-chain simulation/gaming elements, and resource management. It's not a standard token, DeFi, or simple NFT contract.

**Concept:** **Autonomous Agent Network Simulator (AANS)**
A smart contract where users can own and manage programmable agents. Agents have state (e.g., energy, skill, type, generation) and can perform actions that consume/produce resources, interact with other agents, or evolve. The simulation progresses through epochs, potentially triggering events or requiring agent upkeep.

---

**Outline:**

1.  **SPDX-License-Identifier & Pragma**
2.  **Interfaces:** Mock or define necessary interfaces (`IERC20` for resource).
3.  **Libraries:** (None needed for this scope, keeping it self-contained).
4.  **Errors:** Custom errors for clearer failure reasons.
5.  **State Variables:**
    *   Owner
    *   Paused status
    *   Resource token address
    *   Agent Counter (for unique IDs)
    *   Global Simulation Epoch
    *   Environmental Conditions (simulated global state)
    *   Agent data mapping (`uint256 => Agent`)
    *   Agent Type data mapping (`uint256 => AgentType`)
    *   Agent Type counter
    *   Agent ownership mapping (`uint256 => address`) (ERC721-like)
    *   Agent owner token count mapping (`address => uint256`) (ERC721-like)
    *   Agent approvals mapping (`uint256 => address`) (ERC721-like)
    *   Operator approvals mapping (`address => address => bool`) (ERC721-like)
    *   Contract resource balance (implicitly tracked via transfers)
6.  **Structs:**
    *   `AgentType`: Defines base stats/properties for agent archetypes.
    *   `Agent`: Represents an individual agent instance with its current state.
7.  **Events:**
    *   `AgentTypeAdded`
    *   `AgentCreated`
    *   `AgentDestroyed`
    *   `AgentStateChanged`
    *   `ResourcesDeposited`
    *   `ResourcesWithdrawn`
    *   `EpochAdvanced`
    *   `EnvironmentalConditionsChanged`
    *   `SimulationPaused`
    *   `SimulationUnpaused`
    *   ERC721-like events: `Transfer`, `Approval`, `ApprovalForAll`
8.  **Modifiers:**
    *   `onlyOwner`
    *   `whenNotPaused`
    *   `agentExists(uint256 agentId)`
    *   `isAgentOwner(uint256 agentId)`
    *   `isApprovedOrOwner(uint256 agentId)`
    *   `hasEnoughEnergy(uint256 agentId, uint256 requiredEnergy)`
    *   `hasEnoughSkill(uint256 agentId, uint256 requiredSkill)`
    *   `canPerformAction(uint256 agentId, uint256 requiredEnergy, uint256 requiredSkill)`
9.  **Constructor:** Sets owner, initializes epoch.
10. **Core Logic Functions (State Changing):**
    *   `createAgent(uint256 agentTypeId)`: Mints a new agent of a specific type for the caller.
    *   `destroyAgent(uint256 agentId)`: Burns an agent owned by the caller or approved address.
    *   `depositResources(uint256 amount)`: Allows users to deposit the resource token.
    *   `withdrawResources(uint256 amount)`: Allows users to withdraw their entitled resources (simplification: maybe proportional to agents?). *Correction:* A more typical model is users deposit *into* the system for actions, and the system *rewards* them resources based on agent activity. Let's make withdraw only for owner or based on specific rewards earned by agents. Or simplify: allow withdrawal of deposited amounts *if not used*. Let's make it simpler: Withdraw *earned* resources or resources locked *by the contract logic* (not just user deposits). *New Plan:* Deposit for *fueling* agents, agents *earn* resources via actions like `harvestResources`, and users `claimEarnedResources`.
    *   `rechargeAgentEnergy(uint256 agentId, uint256 amount)`: Consume resources to restore agent energy.
    *   `trainAgentSkill(uint256 agentId, uint256 resourceAmount)`: Consume resources and potentially increase agent skill (probabilistic/deterministic).
    *   `mutateAgent(uint256 agentId, uint256 resourceAmount)`: Attempt to mutate an agent (probabilistic, costs resources, might change type or stats significantly).
    *   `ageAgent(uint256 agentId)`: Manually age an agent (might consume upkeep, trigger decay).
    *   `agentInteractionCombat(uint256 agentId1, uint256 agentId2)`: Simulate combat, consume energy/skill, potential resource gain/loss for winner/loser.
    *   `agentInteractionCooperate(uint256 agentId1, uint256 agentId2)`: Simulate cooperation, consume energy, potentially produce resources or state change for both.
    *   `harvestResources(uint256 agentId)`: An agent attempts to harvest resources from the environment (simulated), consuming energy/skill, producing resource tokens.
    *   `advanceEpoch()`: Moves the simulation to the next epoch (restricted access, e.g., time-based or owner). Triggers global effects.
    *   `claimEarnedResources()`: Users claim resources earned by their agents through actions like `harvestResources` or interactions.
11. **ERC721-like Functions (Manual Implementation):**
    *   `transferFrom(address from, address to, uint256 agentId)`: Transfer agent ownership.
    *   `approve(address to, uint256 agentId)`: Approve one address to transfer a specific agent.
    *   `setApprovalForAll(address operator, bool approved)`: Approve an operator for all caller's agents.
12. **Admin/Owner Functions:**
    *   `addAgentType(string memory name, uint256 baseEnergy, uint256 baseSkill, uint256 creationCost)`: Define a new agent archetype.
    *   `setResourceToken(address resourceTokenAddress)`: Set the address of the ERC20 resource.
    *   `setEnvironmentalConditions(uint256 newConditions)`: Update global simulated conditions.
    *   `pauseSimulation()`: Pause key actions.
    *   `unpauseSimulation()`: Unpause simulation.
    *   `transferOwnership(address newOwner)`: Standard ownership transfer.
13. **Query Functions (View/Pure):**
    *   `getAgentDetails(uint256 agentId)`: Get full state of an agent.
    *   `getAgentTypeDetails(uint256 agentTypeId)`: Get details of an agent type.
    *   `getSimulationEpoch()`: Get current epoch.
    *   `getAgentCount()`: Total number of agents created.
    *   `getAgentOwner(uint256 agentId)`: Get owner of an agent (ERC721-like).
    *   `balanceOf(address owner)`: Get number of agents owned by an address (ERC721-like).
    *   `getApproved(uint256 agentId)`: Get approved address for an agent (ERC721-like).
    *   `isApprovedForAll(address owner, address operator)`: Check operator approval (ERC721-like).
    *   `getEarnedResources(address owner)`: Get resources an owner is eligible to claim.

**Function Summary (28 functions listed):**

*   `addAgentType(string name, uint256 baseEnergy, uint256 baseSkill, uint256 creationCost)`: Defines a new blueprint for agents. (Admin)
*   `setResourceToken(address resourceTokenAddress)`: Sets the ERC20 token used for resources. (Admin)
*   `setEnvironmentalConditions(uint256 newConditions)`: Updates a global state variable affecting simulation outcomes. (Admin)
*   `pauseSimulation()`: Halts state-changing actions. (Admin)
*   `unpauseSimulation()`: Resumes state-changing actions. (Admin)
*   `transferOwnership(address newOwner)`: Changes contract admin. (Admin)
*   `createAgent(uint256 agentTypeId)`: Creates a new agent instance of a specific type, costing resources. (Public)
*   `destroyAgent(uint256 agentId)`: Permanently removes an agent, potentially recouping partial resources. (Public)
*   `depositResources(uint256 amount)`: Sends resource tokens to the contract, usable by caller's agents. (Public)
*   `rechargeAgentEnergy(uint256 agentId, uint256 amount)`: Spends deposited resources to increase an agent's energy. (Public)
*   `trainAgentSkill(uint256 agentId, uint256 resourceAmount)`: Spends deposited resources attempting to increase an agent's skill. (Public)
*   `mutateAgent(uint256 agentId, uint256 resourceAmount)`: Attempts a probabilistic mutation, possibly changing agent type or stats, consuming resources. (Public)
*   `ageAgent(uint256 agentId)`: Advances an agent's age counter, potentially triggering effects or requiring upkeep. (Public)
*   `agentInteractionCombat(uint256 agentId1, uint256 agentId2)`: Simulates combat between two agents, affecting their state and potentially transferring resources. (Public)
*   `agentInteractionCooperate(uint256 agentId1, uint256 agentId2)`: Simulates cooperation, potentially yielding shared benefits or resources. (Public)
*   `harvestResources(uint256 agentId)`: An agent attempts to gather resources from the simulated environment, adding to owner's claimable balance. (Public)
*   `advanceEpoch()`: Progresses the simulation to the next time step, triggering global/passive effects. (Restricted, e.g., time or owner)
*   `claimEarnedResources()`: Allows a user to withdraw resources earned by their agents. (Public)
*   `transferFrom(address from, address to, uint256 agentId)`: Transfers ownership of an agent (ERC721-like). (Public)
*   `approve(address to, uint256 agentId)`: Grants transfer approval for a specific agent (ERC721-like). (Public)
*   `setApprovalForAll(address operator, bool approved)`: Grants/revokes operator approval for all caller's agents (ERC721-like). (Public)
*   `getAgentDetails(uint256 agentId)`: Reads the full state data of an agent. (View)
*   `getAgentTypeDetails(uint256 agentTypeId)`: Reads the blueprint data for an agent type. (View)
*   `getSimulationEpoch()`: Reads the current simulation epoch. (View)
*   `getAgentCount()`: Reads the total number of agents minted. (View)
*   `getAgentOwner(uint256 agentId)`: Reads the owner address of an agent (ERC721-like). (View)
*   `balanceOf(address owner)`: Reads the number of agents owned by an address (ERC721-like). (View)
*   `getEarnedResources(address owner)`: Reads the amount of resources an owner can claim. (View)

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Mock IERC20 interface for resource token interaction
interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
}

/**
 * @title Autonomous Agent Network Simulator (AANS)
 * @dev A contract simulating a network of programmable on-chain agents (NFTs).
 * Agents have dynamic state, interact, consume/produce resources, and evolve
 * within a global epoch system. Implements ERC721-like ownership functionality manually.
 */

// Outline:
// 1. SPDX-License-Identifier & Pragma
// 2. Interfaces: IERC20 (mock)
// 3. Errors
// 4. State Variables
// 5. Structs: AgentType, Agent
// 6. Events
// 7. Modifiers
// 8. Constructor
// 9. Core Logic Functions (State Changing)
// 10. ERC721-like Functions (Manual Implementation)
// 11. Admin/Owner Functions
// 12. Query Functions (View/Pure)

// Function Summary (28 functions):
// - addAgentType(string name, uint256 baseEnergy, uint256 baseSkill, uint256 creationCost): Defines a new blueprint for agents. (Admin)
// - setResourceToken(address resourceTokenAddress): Sets the ERC20 token used for resources. (Admin)
// - setEnvironmentalConditions(uint256 newConditions): Updates a global state variable affecting simulation outcomes. (Admin)
// - pauseSimulation(): Halts state-changing actions. (Admin)
// - unpauseSimulation(): Resumes state-changing actions. (Admin)
// - transferOwnership(address newOwner): Changes contract admin. (Admin)
// - createAgent(uint256 agentTypeId): Creates a new agent instance of a specific type, costing resources. (Public)
// - destroyAgent(uint256 agentId): Permanently removes an agent, potentially recouping partial resources. (Public)
// - depositResources(uint256 amount): Sends resource tokens to the contract, usable by caller's agents. (Public)
// - rechargeAgentEnergy(uint256 agentId, uint256 amount): Spends deposited resources to increase an agent's energy. (Public)
// - trainAgentSkill(uint256 agentId, uint256 resourceAmount): Spends deposited resources attempting to increase an agent's skill. (Public)
// - mutateAgent(uint256 agentId, uint256 resourceAmount): Attempts a probabilistic mutation, possibly changing agent type or stats, consuming resources. (Public)
// - ageAgent(uint256 agentId): Advances an agent's age counter, potentially triggering effects or requiring upkeep. (Public)
// - agentInteractionCombat(uint256 agentId1, uint256 agentId2): Simulates combat between two agents, affecting their state and potentially transferring resources. (Public)
// - agentInteractionCooperate(uint256 agentId1, uint256 agentId2): Simulates cooperation, potentially yielding shared benefits or resources. (Public)
// - harvestResources(uint256 agentId): An agent attempts to gather resources from the simulated environment, adding to owner's claimable balance. (Public)
// - advanceEpoch(): Progresses the simulation to the next time step, triggering global/passive effects. (Restricted, e.g., time or owner)
// - claimEarnedResources(): Allows a user to withdraw resources earned by their agents. (Public)
// - transferFrom(address from, address to, uint256 agentId): Transfers ownership of an agent (ERC721-like). (Public)
// - approve(address to, uint256 agentId): Grants transfer approval for a specific agent (ERC721-like). (Public)
// - setApprovalForAll(address operator, bool approved): Grants/revokes operator approval for all caller's agents (ERC721-like). (Public)
// - getAgentDetails(uint256 agentId): Reads the full state data of an agent. (View)
// - getAgentTypeDetails(uint256 agentTypeId): Reads the blueprint data for an agent type. (View)
// - getSimulationEpoch(): Reads the current simulation epoch. (View)
// - getAgentCount(): Reads the total number of agents minted. (View)
// - getAgentOwner(uint256 agentId): Reads the owner address of an agent (ERC721-like). (View)
// - balanceOf(address owner): Reads the number of agents owned by an address (ERC721-like). (View)
// - getEarnedResources(address owner): Reads the amount of resources an owner can claim. (View)

error InvalidAgentId();
error NotAgentOwner();
error NotApprovedOrOwner();
error SimulationPaused();
error SimulationNotPaused();
error InsufficientEnergy();
error InsufficientSkill();
error ResourceTokenNotSet();
error AgentTypeDoesNotExist();
error InsufficientResourcesDeposited();
error NoResourcesToClaim();
error SelfInteractionNotAllowed();
error AgentsMustBeDifferentTypesForReproduction();
error ReproductionFailed();
error MutationFailed();
error CombatFailed();

contract AutonomousAgentNetworkSimulator {
    address public owner;
    bool public paused;
    IERC20 public resourceToken;

    uint256 private _nextAgentId;
    uint256 private _nextAgentTypeId;
    uint256 public currentEpoch;
    uint256 public environmentalConditions; // Example: Affects harvest yield, interaction success probability

    struct AgentType {
        string name;
        uint256 baseEnergy;
        uint256 baseSkill;
        uint256 creationCost; // Cost in resource tokens
    }

    struct Agent {
        uint256 id;
        uint256 agentTypeId;
        uint256 currentEnergy;
        uint256 currentSkill;
        uint256 generation; // How many reproduction cycles it's descended from
        uint256 age;        // Epochs since creation
        // Add more state variables as needed, e.g., traits, status effects, lastActionEpoch
    }

    mapping(uint256 => Agent) private _agents;
    mapping(uint256 => AgentType) private _agentTypes;

    // ERC721-like state
    mapping(uint256 => address) private _agentOwners;
    mapping(address => uint256) private _ownerAgentCount; // ERC721 balanceOf
    mapping(uint256 => address) private _tokenApprovals; // ERC721 getApproved
    mapping(address => mapping(address => bool)) private _operatorApprovals; // ERC721 isApprovedForAll

    // Resource management state
    mapping(address => uint256) private _depositedResources; // Resources deposited by user for their agents
    mapping(address => uint256) private _earnedResources; // Resources earned by agents, claimable by user

    event AgentTypeAdded(uint256 indexed agentTypeId, string name, uint256 creationCost);
    event AgentCreated(uint256 indexed agentId, address indexed owner, uint256 indexed agentTypeId, uint256 epoch);
    event AgentDestroyed(uint256 indexed agentId, address indexed owner, uint256 epoch);
    event AgentStateChanged(uint256 indexed agentId, uint256 oldEnergy, uint256 newEnergy, uint256 oldSkill, uint256 newSkill);
    event ResourcesDeposited(address indexed user, uint256 amount);
    event ResourcesWithdrawn(address indexed user, uint256 amount);
    event ResourcesClaimed(address indexed user, uint256 amount);
    event EpochAdvanced(uint256 newEpoch, uint256 oldEpoch);
    event EnvironmentalConditionsChanged(uint256 newConditions, uint256 oldConditions);
    event SimulationPaused();
    event SimulationUnpaused();
    event AgentMutated(uint256 indexed agentId, uint256 indexed newAgentTypeId, uint256 indexed newGeneration);
    event AgentAged(uint256 indexed agentId, uint256 newAge);
    event AgentInteraction(uint256 indexed agentId1, uint256 indexed agentId2, string interactionType, bool success);

    // ERC721-like events
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    modifier onlyOwner() {
        if (msg.sender != owner) revert OwnableUnauthorizedAccount(msg.sender); // Use standard error if available, or define custom
        _;
    }

    modifier whenNotPaused() {
        if (paused) revert SimulationPaused();
        _;
    }

    modifier agentExists(uint256 agentId) {
        if (_agentOwners[agentId] == address(0)) revert InvalidAgentId();
        _;
    }

    modifier isAgentOwner(uint256 agentId) {
        if (_agentOwners[agentId] != msg.sender) revert NotAgentOwner();
        _;
    }

    modifier isApprovedOrOwner(uint256 agentId) {
        address agentOwner = _agentOwners[agentId];
        if (agentOwner == address(0)) revert InvalidAgentId(); // Should be caught by agentExists, but belt-and-suspenders
        if (agentOwner != msg.sender && _tokenApprovals[agentId] != msg.sender && !_operatorApprovals[agentOwner][msg.sender]) {
            revert NotApprovedOrOwner();
        }
        _;
    }

    modifier hasEnoughEnergy(uint256 agentId, uint256 requiredEnergy) {
        if (_agents[agentId].currentEnergy < requiredEnergy) revert InsufficientEnergy();
        _;
    }

     modifier hasEnoughSkill(uint256 agentId, uint256 requiredSkill) {
        if (_agents[agentId].currentSkill < requiredSkill) revert InsufficientSkill();
        _;
    }

    modifier canPerformAction(uint256 agentId, uint256 requiredEnergy, uint256 requiredSkill) {
        // Check agent exists, energy, skill, and if simulation is paused
        // Note: whenNotPaused should be applied to the function itself, not this modifier
        // Adding agentExists here for convenience in multi-agent functions
        if (_agentOwners[agentId] == address(0)) revert InvalidAgentId();
        if (_agents[agentId].currentEnergy < requiredEnergy) revert InsufficientEnergy();
        if (_agents[agentId].currentSkill < requiredSkill) revert InsufficientSkill();
        _;
    }


    // Custom error definition if not using OpenZeppelin's Ownable
    error OwnableUnauthorizedAccount(address account);

    constructor() {
        owner = msg.sender;
        paused = false;
        _nextAgentId = 1; // Start agent IDs from 1
        _nextAgentTypeId = 1; // Start type IDs from 1
        currentEpoch = 0;
        environmentalConditions = 100; // Default environmental conditions
    }

    // --- Admin Functions ---

    /// @notice Adds a new agent type blueprint. Only callable by the owner.
    /// @param name The name of the agent type.
    /// @param baseEnergy The base energy for this agent type.
    /// @param baseSkill The base skill for this agent type.
    /// @param creationCost The cost in resource tokens to create an agent of this type.
    function addAgentType(string memory name, uint256 baseEnergy, uint256 baseSkill, uint256 creationCost) external onlyOwner {
        uint256 typeId = _nextAgentTypeId++;
        _agentTypes[typeId] = AgentType({
            name: name,
            baseEnergy: baseEnergy,
            baseSkill: baseSkill,
            creationCost: creationCost
        });
        emit AgentTypeAdded(typeId, name, creationCost);
    }

    /// @notice Sets the address of the ERC20 resource token used in the simulation. Only callable by the owner.
    /// @param resourceTokenAddress The address of the ERC20 token contract.
    function setResourceToken(address resourceTokenAddress) external onlyOwner {
        resourceToken = IERC20(resourceTokenAddress);
        emit ResourceTokenNotSet(); // Use this to indicate it's now set
    }

    /// @notice Sets the global environmental conditions. Only callable by the owner.
    /// @param newConditions The new value for environmental conditions.
    function setEnvironmentalConditions(uint256 newConditions) external onlyOwner {
        uint256 oldConditions = environmentalConditions;
        environmentalConditions = newConditions;
        emit EnvironmentalConditionsChanged(newConditions, oldConditions);
    }

    /// @notice Pauses simulation actions. Only callable by the owner.
    function pauseSimulation() external onlyOwner {
        if (paused) revert SimulationPaused();
        paused = true;
        emit SimulationPaused();
    }

    /// @notice Unpauses simulation actions. Only callable by the owner.
    function unpauseSimulation() external onlyOwner {
        if (!paused) revert SimulationNotPaused();
        paused = false;
        emit SimulationUnpaused();
    }

    /// @notice Transfers ownership of the contract. Only callable by the current owner.
    /// @param newOwner The address of the new owner.
    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) revert OwnableUnauthorizedAccount(address(0)); // Use standard error
        owner = newOwner;
        // No specific event defined, but standard Ownable contracts emit OwnershipTransferred.
        // We will omit for simplicity, relying on the state change.
    }

    // --- Core Logic Functions (State Changing) ---

    /// @notice Creates a new agent of a specified type for the caller. Costs resource tokens.
    /// @param agentTypeId The ID of the agent type blueprint to use.
    function createAgent(uint256 agentTypeId) external whenNotPaused {
        if (address(resourceToken) == address(0)) revert ResourceTokenNotSet();
        AgentType storage agentType = _agentTypes[agentTypeId];
        if (bytes(agentType.name).length == 0) revert AgentTypeDoesNotExist(); // Check if type exists

        // Require deposit or allow direct transferFrom? Let's use deposited resources.
        if (_depositedResources[msg.sender] < agentType.creationCost) revert InsufficientResourcesDeposited();

        _depositedResources[msg.sender] -= agentType.creationCost;

        uint256 newId = _nextAgentId++;
        _agents[newId] = Agent({
            id: newId,
            agentTypeId: agentTypeId,
            currentEnergy: agentType.baseEnergy,
            currentSkill: agentType.baseSkill,
            generation: 1,
            age: 0
        });

        // ERC721-like minting
        _agentOwners[newId] = msg.sender;
        _ownerAgentCount[msg.sender]++;
        emit Transfer(address(0), msg.sender, newId);

        emit AgentCreated(newId, msg.sender, agentTypeId, currentEpoch);
    }

    /// @notice Destroys an agent. Must be called by the owner or an approved address.
    /// @param agentId The ID of the agent to destroy.
    function destroyAgent(uint256 agentId) external whenNotPaused agentExists(agentId) isApprovedOrOwner(agentId) {
        address agentOwner = _agentOwners[agentId];
        uint256 ownerAgentCount = _ownerAgentCount[agentOwner];

        // Clear approvals
        delete _tokenApprovals[agentId];

        // ERC721-like burning
        delete _agentOwners[agentId];
        _ownerAgentCount[agentOwner] = ownerAgentCount - 1; // Safe subtraction assuming ownerAgentCount > 0 due to agentExists check

        delete _agents[agentId]; // Remove agent data

        emit Transfer(agentOwner, address(0), agentId);
        emit AgentDestroyed(agentId, agentOwner, currentEpoch);
    }

    /// @notice Deposits resource tokens into the contract, associated with the caller's address.
    /// @param amount The amount of resource tokens to deposit.
    function depositResources(uint256 amount) external whenNotPaused {
        if (address(resourceToken) == address(0)) revert ResourceTokenNotSet();
        // Transfer tokens from the user to the contract
        bool success = resourceToken.transferFrom(msg.sender, address(this), amount);
        if (!success) revert InsufficientResourcesDeposited(); // Or a more specific transfer error

        _depositedResources[msg.sender] += amount;
        emit ResourcesDeposited(msg.sender, amount);
    }

     /// @notice Allows users to claim resources earned by their agents.
    function claimEarnedResources() external whenNotPaused {
        uint256 amount = _earnedResources[msg.sender];
        if (amount == 0) revert NoResourcesToClaim();
        if (address(resourceToken) == address(0)) revert ResourceTokenNotSet();

        _earnedResources[msg.sender] = 0; // Reset earned balance before transfer
        bool success = resourceToken.transfer(msg.sender, amount);

        if (!success) {
            // If transfer fails, revert the earned balance update
            _earnedResources[msg.sender] = amount;
            revert ResourcesWithdrawn(); // Indicate withdrawal failure
        }
        emit ResourcesClaimed(msg.sender, amount);
    }


    /// @notice Spends deposited resources to increase an agent's current energy.
    /// @param agentId The ID of the agent to recharge.
    /// @param amount The amount of energy to restore (costs corresponding resources).
    function rechargeAgentEnergy(uint256 agentId, uint256 amount) external whenNotPaused isAgentOwner(agentId) agentExists(agentId) {
        // Cost: 1 resource per 1 energy point (example)
        uint256 cost = amount;
        if (_depositedResources[msg.sender] < cost) revert InsufficientResourcesDeposited();

        _depositedResources[msg.sender] -= cost;
        _agents[agentId].currentEnergy += amount; // Cap energy at max? Add max_energy to Agent/AgentType?
        emit AgentStateChanged(agentId, _agents[agentId].currentEnergy - amount, _agents[agentId].currentEnergy, _agents[agentId].currentSkill, _agents[agentId].currentSkill);
    }

    /// @notice Attempts to increase an agent's skill by spending resources. May be probabilistic.
    /// @param agentId The ID of the agent to train.
    /// @param resourceAmount The amount of resources to spend on training.
    function trainAgentSkill(uint256 agentId, uint256 resourceAmount) external whenNotPaused isAgentOwner(agentId) agentExists(agentId) {
        if (_depositedResources[msg.sender] < resourceAmount) revert InsufficientResourcesDeposited();

        _depositedResources[msg.sender] -= resourceAmount;

        // --- Probabilistic Skill Increase (Example) ---
        // Use block data for pseudo-randomness - INSECURE for high-value games, use VRF!
        uint256 randomness = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, agentId, resourceAmount)));
        uint256 skillIncrease = (randomness % (resourceAmount / 10 + 1)); // Example logic: more resources -> higher chance/amount
        if (skillIncrease > 0) {
             _agents[agentId].currentSkill += skillIncrease;
             emit AgentStateChanged(agentId, _agents[agentId].currentEnergy, _agents[agentId].currentEnergy, _agents[agentId].currentSkill - skillIncrease, _agents[agentId].currentSkill);
        }
        // No event if skill increase is 0 to avoid spam

        // Add more complex logic: skill cap, diminishing returns, specific agent types train differently, etc.
    }


    /// @notice Attempts to mutate an agent into a potentially different state or type. Probabilistic, costs resources.
    /// @param agentId The ID of the agent to mutate.
    /// @param resourceAmount The amount of resources to spend on mutation.
    function mutateAgent(uint256 agentId, uint256 resourceAmount) external whenNotPaused isAgentOwner(agentId) agentExists(agentId) {
         if (_depositedResources[msg.sender] < resourceAmount) revert InsufficientResourcesDeposited();

        _depositedResources[msg.sender] -= resourceAmount;

        // --- Probabilistic Mutation (Example) ---
        // INSECURE pseudo-randomness! Use VRF for production.
        uint256 randomness = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, agentId, currentEpoch, resourceAmount)));

        // Example mutation logic:
        // - 10% chance to increase generation
        // - 5% chance to change agent type (to a random existing one?)
        // - X% chance to slightly boost random stats (energy/skill)
        // - Y% chance to slightly decrease random stats
        // - Z% chance of catastrophic failure (agent destroyed?) - maybe too harsh for example
        // - Success chance modified by resourceAmount, environmentalConditions, agent's current stats/age

        uint256 successRoll = randomness % 100; // Roll 0-99
        bool mutated = false;
        uint256 oldEnergy = _agents[agentId].currentEnergy;
        uint256 oldSkill = _agents[agentId].currentSkill;
        uint256 oldTypeId = _agents[agentId].agentTypeId;
        uint256 oldGeneration = _agents[agentId].generation;

        if (successRoll < 15) { // 15% chance of *some* mutation
             uint256 mutationTypeRoll = randomness / 100 % 3; // Roll 0, 1, or 2

             if (mutationTypeRoll == 0) { // Increase generation (e.g., 5% of the 15%)
                _agents[agentId].generation++;
                mutated = true;
             } else if (mutationTypeRoll == 1 && _nextAgentTypeId > 1) { // Change type (e.g., 5% of the 15%)
                 uint256 newTypeId = (randomness / 1000 % (_nextAgentTypeId - 1)) + 1; // Pick a random existing type
                 _agents[agentId].agentTypeId = newTypeId;
                 // Maybe reset stats based on new type base stats?
                 _agents[agentId].currentEnergy = _agentTypes[newTypeId].baseEnergy;
                 _agents[agentId].currentSkill = _agentTypes[newTypeId].baseSkill;
                 mutated = true;
             } else { // Stat boost/decrease (e.g., 5% of the 15%)
                 uint256 statRoll = randomness / 10000 % 2; // 0 for energy, 1 for skill
                 int256 change = int256((randomness / 100000 % 20) - 10); // Change between -10 and +9

                 if (statRoll == 0) {
                     int256 newEnergy = int256(_agents[agentId].currentEnergy) + change;
                     _agents[agentId].currentEnergy = uint256(newEnergy > 0 ? newEnergy : 0);
                 } else {
                     int256 newSkill = int256(_agents[agentId].currentSkill) + change;
                     _agents[agentId].currentSkill = uint256(newSkill > 0 ? newSkill : 0);
                 }
                 mutated = true;
             }
        }

        if (mutated) {
             emit AgentMutated(agentId, _agents[agentId].agentTypeId, _agents[agentId].generation);
             // Emit state changed if stats changed
             if (oldEnergy != _agents[agentId].currentEnergy || oldSkill != _agents[agentId].currentSkill) {
                  emit AgentStateChanged(agentId, oldEnergy, _agents[agentId].currentEnergy, oldSkill, _agents[agentId].currentSkill);
             }
        } else {
             // Optionally emit a MutationFailed event
             revert MutationFailed(); // Revert if mutation didn't happen this time (or just let it pass silently?) Let's revert for clarity.
        }
    }


    /// @notice Advances an agent's age by one epoch. May require resource upkeep or cause decay.
    /// @dev This could be called by the owner, or maybe passively triggered by advanceEpoch (more complex).
    /// Let's make it owner-triggered for simplicity in this example.
    /// @param agentId The ID of the agent to age.
    function ageAgent(uint256 agentId) external whenNotPaused isAgentOwner(agentId) agentExists(agentId) {
        // Example: Require upkeep cost based on age/generation
        uint256 upkeepCost = _agents[agentId].age * 10 + _agents[agentId].generation * 5; // Example formula
        if (_depositedResources[msg.sender] < upkeepCost) revert InsufficientResourcesDeposited();

        _depositedResources[msg.sender] -= upkeepCost;
        _agents[agentId].age++;

        // Example: Decay stats slightly with age
        if (_agents[agentId].currentEnergy > 0) _agents[agentId].currentEnergy -= (_agents[agentId].currentEnergy / 100); // 1% decay
        if (_agents[agentId].currentSkill > 0) _agents[agentId].currentSkill -= (_agents[agentId].currentSkill / 200); // 0.5% decay

        emit AgentAged(agentId, _agents[agentId].age);
        emit AgentStateChanged(agentId, _agents[agentId].currentEnergy + (_agents[agentId].currentEnergy / 100), _agents[agentId].currentEnergy, _agents[agentId].currentSkill + (_agents[agentId].currentSkill / 200), _agents[agentId].currentSkill);
    }


    /// @notice Simulates combat interaction between two agents.
    /// @param agentId1 The ID of the first agent.
    /// @param agentId2 The ID of the second agent.
    function agentInteractionCombat(uint256 agentId1, uint256 agentId2)
        external
        whenNotPaused
        agentExists(agentId1) // Assumes caller owns agentId1 or is approved
        agentExists(agentId2) // Assumes agentId2 exists, owner doesn't matter for interaction target
    {
        if (agentId1 == agentId2) revert SelfInteractionNotAllowed();
        // We need to check if the caller owns or is approved for agentId1
        isApprovedOrOwner(agentId1); // Reverts if not approved/owner

        Agent storage agent1 = _agents[agentId1];
        Agent storage agent2 = _agents[agentId2];

        // Example Combat Logic:
        // - Both agents consume energy
        // - Compare skill + random factor
        // - Winner takes some resources, Loser loses skill/energy

        uint256 energyCost = 20; // Example cost
        if (agent1.currentEnergy < energyCost) revert InsufficientEnergy(); // Agent 1 needs energy
         // Note: Agent 2 might not need energy if it's passive defense, or it might need energy too.
         // For simplicity, let's assume both consume energy if they have it.
         uint256 agent2EnergyCost = agent2.currentEnergy >= energyCost ? energyCost : agent2.currentEnergy; // Agent 2 uses what it has

        agent1.currentEnergy -= energyCost;
        agent2.currentEnergy -= agent2EnergyCost;

        // INSECURE pseudo-randomness!
        uint256 randomness = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, agentId1, agentId2, currentEpoch)));

        // Simple skill comparison with randomness (e.g., +/- 10%)
        int256 skill1Effective = int256(agent1.currentSkill) + int256((randomness % (agent1.currentSkill / 5 + 1)) - (agent1.currentSkill / 10));
        int256 skill2Effective = int256(agent2.currentSkill) + int256((randomness / 100 % (agent2.currentSkill / 5 + 1)) - (agent2.currentSkill / 10));

        bool agent1Wins = skill1Effective > skill2Effective;

        uint256 oldEnergy1 = agent1.currentEnergy + energyCost; // Before deduction
        uint256 oldSkill1 = agent1.currentSkill;
        uint256 oldEnergy2 = agent2.currentEnergy + agent2EnergyCost; // Before deduction
        uint256 oldSkill2 = agent2.currentSkill;


        if (agent1Wins) {
            // Agent 1 wins: gains some skill, maybe resources from environment (or agent2?), Agent 2 loses skill/energy
            agent1.currentSkill += (agent2.currentSkill / 10); // Gain 10% of opponent's skill (example)
             if (_agentOwners[agentId1] != address(0)) { // Ensure owner still exists
                _earnedResources[_agentOwners[agentId1]] += 50; // Agent 1 owner earns resources (example)
             }
            agent2.currentSkill = agent2.currentSkill > (agent2.currentSkill / 5) ? agent2.currentSkill - (agent2.currentSkill / 5) : 0; // Agent 2 loses 20% skill (example)
             // Agent 2 already lost energy

            emit AgentInteraction(agentId1, agentId2, "CombatWin", true);
            // Emit state changes for both agents
             emit AgentStateChanged(agentId1, oldEnergy1, agent1.currentEnergy, oldSkill1, agent1.currentSkill);
             emit AgentStateChanged(agentId2, oldEnergy2, agent2.currentEnergy, oldSkill2, agent2.currentSkill);

        } else {
             // Agent 2 wins (or draw, for simplicity let's say agent2 wins if agent1 doesn't)
             // Agent 2 gains some skill, resources. Agent 1 loses skill/energy.
            agent2.currentSkill += (agent1.currentSkill / 10);
             if (_agentOwners[agentId2] != address(0)) { // Ensure owner still exists
                 _earnedResources[_agentOwners[agentId2]] += 50; // Agent 2 owner earns resources
             }
            agent1.currentSkill = agent1.currentSkill > (agent1.currentSkill / 5) ? agent1.currentSkill - (agent1.currentSkill / 5) : 0;
            // Agent 1 already lost energy

            emit AgentInteraction(agentId1, agentId2, "CombatLoss", true); // Agent 1 perspective
             // Emit state changes for both agents
             emit AgentStateChanged(agentId1, oldEnergy1, agent1.currentEnergy, oldSkill1, agent1.currentSkill);
             emit AgentStateChanged(agentId2, oldEnergy2, agent2.currentEnergy, oldSkill2, agent2.currentSkill);

        }
        // Could potentially destroy losing agent based on outcome/damage received.
    }

     /// @notice Simulates cooperation interaction between two agents.
    /// @param agentId1 The ID of the first agent.
    /// @param agentId2 The ID of the second agent.
    function agentInteractionCooperate(uint256 agentId1, uint256 agentId2)
        external
        whenNotPaused
        agentExists(agentId1) // Assumes caller owns agentId1 or is approved
        agentExists(agentId2) // Assumes agentId2 exists
    {
        if (agentId1 == agentId2) revert SelfInteractionNotAllowed();
         // Need to check if caller owns/approved agentId1.
         // For simplicity, let's require caller owns/approved *both* agents for cooperation.
         // A more advanced version could require approval from *both* owners.
        isApprovedOrOwner(agentId1);
        isApprovedOrOwner(agentId2); // Requires caller is owner/approved for both

        Agent storage agent1 = _agents[agentId1];
        Agent storage agent2 = _agents[agentId2];

        // Example Cooperation Logic:
        // - Both agents consume energy
        // - Combined skill determines success chance/resource yield
        // - Both owners gain resources

        uint256 energyCost = 15; // Example cost per agent
        if (agent1.currentEnergy < energyCost || agent2.currentEnergy < energyCost) revert InsufficientEnergy();

        agent1.currentEnergy -= energyCost;
        agent2.currentEnergy -= energyCost;

        uint256 oldEnergy1 = agent1.currentEnergy + energyCost;
        uint256 oldEnergy2 = agent2.currentEnergy + energyCost;
        uint256 oldSkill1 = agent1.currentSkill;
        uint256 oldSkill2 = agent2.currentSkill;

        uint256 combinedSkill = agent1.currentSkill + agent2.currentSkill;

        // INSECURE pseudo-randomness!
        uint256 randomness = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, agentId1, agentId2, currentEpoch, "cooperate")));

        // Success chance based on combined skill and environment
        uint256 successThreshold = combinedSkill / 10 + environmentalConditions / 5; // Example formula
        bool success = (randomness % 100) < successThreshold;

        if (success) {
             uint256 resourcesEarned = combinedSkill + environmentalConditions; // Example yield
             address owner1 = _agentOwners[agentId1];
             address owner2 = _agentOwners[agentId2];

             if (owner1 != address(0)) _earnedResources[owner1] += resourcesEarned / 2;
             if (owner2 != address(0)) _earnedResources[owner2] += resourcesEarned - (resourcesEarned / 2); // Give remainder to second

             // Small skill gain for both
             agent1.currentSkill += 1;
             agent2.currentSkill += 1;

            emit AgentInteraction(agentId1, agentId2, "CooperateSuccess", true);
             emit AgentStateChanged(agentId1, oldEnergy1, agent1.currentEnergy, oldSkill1, agent1.currentSkill);
             emit AgentStateChanged(agentId2, oldEnergy2, agent2.currentEnergy, oldSkill2, agent2.currentSkill);

        } else {
            // On failure, just energy loss, maybe small skill loss
            agent1.currentSkill = agent1.currentSkill > 0 ? agent1.currentSkill - 1 : 0;
            agent2.currentSkill = agent2.currentSkill > 0 ? agent2.currentSkill - 1 : 0;
            emit AgentInteraction(agentId1, agentId2, "CooperateFail", false);
             emit AgentStateChanged(agentId1, oldEnergy1, agent1.currentEnergy, oldSkill1, agent1.currentSkill);
             emit AgentStateChanged(agentId2, oldEnergy2, agent2.currentEnergy, oldSkill2, agent2.currentSkill);
        }
    }


    /// @notice Allows an agent (specifically a 'Harvester' type, example) to attempt to harvest resources.
    /// @param agentId The ID of the agent performing the harvest.
    function harvestResources(uint256 agentId) external whenNotPaused isAgentOwner(agentId) agentExists(agentId) {
        Agent storage agent = _agents[agentId];
        AgentType storage agentType = _agentTypes[agent.agentTypeId];

        // Example: Only agents of a specific type can harvest (e.g., type 2)
        // if (agent.agentTypeId != 2) revert AgentTypeCannotHarvest(); // Add specific error/modifier

        uint256 energyCost = 10;
        uint256 skillCost = 5; // Harvesting also requires skill
        canPerformAction(agentId, energyCost, skillCost); // Checks existence, energy, skill

        agent.currentEnergy -= energyCost;
        agent.currentSkill -= skillCost;

        uint256 oldEnergy = agent.currentEnergy + energyCost;
        uint256 oldSkill = agent.currentSkill + skillCost;

        // INSECURE pseudo-randomness!
        uint256 randomness = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, agentId, currentEpoch, environmentalConditions)));

        // Example Harvest Logic:
        // - Yield based on agent skill, environmental conditions, and randomness
        uint256 baseYield = 10;
        uint256 yieldAmount = baseYield + (agent.currentSkill / 2) + (environmentalConditions / 10) + (randomness % 20); // Example formula

        if (yieldAmount > 0) {
            address owner = _agentOwners[agentId];
            if (owner != address(0)) { // Defensive check
                 _earnedResources[owner] += yieldAmount;
                 emit AgentInteraction(agentId, 0, "HarvestSuccess", true); // 0 for targetId indicates self or environment interaction
                 // No specific event for resource *earned* here, rely on claimEarnedResources event
            }
        } else {
             emit AgentInteraction(agentId, 0, "HarvestFail", false);
        }

        emit AgentStateChanged(agentId, oldEnergy, agent.currentEnergy, oldSkill, agent.currentSkill);
    }

    /// @notice Advances the simulation to the next epoch.
    /// @dev This should ideally be triggered by time or another mechanism in a real game,
    /// but is owner-only for simplicity in this example.
    function advanceEpoch() external onlyOwner whenNotPaused {
        uint256 oldEpoch = currentEpoch;
        currentEpoch++;

        // --- Global Epoch Effects (Example) ---
        // - Agents lose a small amount of energy/skill passively
        // - Environmental conditions might change randomly
        // - Resource nodes regenerate (if they existed)

        // Iterate through all agents to apply passive effects (gas heavy for many agents!)
        // A better approach for production would be lazy updates or batched processing.
        // Skipping iteration in this example to save complexity and gas.

        // Example: Environmental conditions change randomly (INSECURE!)
        uint256 randomness = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, currentEpoch)));
        uint256 oldConditions = environmentalConditions;
        environmentalConditions = oldConditions + (randomness % 20) - 10; // Change by -10 to +9

        emit EpochAdvanced(currentEpoch, oldEpoch);
        if (oldConditions != environmentalConditions) {
             emit EnvironmentalConditionsChanged(environmentalConditions, oldConditions);
        }
    }

    /// @notice Simulates reproduction between two agents. Probabilistic, costs resources, creates new agent.
    /// @dev Requires caller owns/approved both agents. Complex logic possible for inheriting traits.
    /// @param agentId1 The ID of the first parent agent.
    /// @param agentId2 The ID of the second parent agent.
    function agentInteractionReproduce(uint256 agentId1, uint256 agentId2)
        external
        whenNotPaused
        agentExists(agentId1)
        agentExists(agentId2)
    {
        if (agentId1 == agentId2) revert SelfInteractionNotAllowed();
         // Require caller owns/approved both parents
        isApprovedOrOwner(agentId1);
        isApprovedOrOwner(agentId2);

        Agent storage agent1 = _agents[agentId1];
        Agent storage agent2 = _agents[agentId2];

        // Example Reproduction Logic:
        // - Requires high energy from both
        // - Cost resources
        // - Success chance based on generation, energy, environmentalConditions, types?
        // - Child inherits traits/stats (average, mix, random?)
        // - Child generation is max(parent generations) + 1

        uint256 energyCost = 50; // High energy cost
        uint256 resourceCost = 200; // Resource cost

        if (agent1.currentEnergy < energyCost || agent2.currentEnergy < energyCost) revert InsufficientEnergy();
        if (_depositedResources[msg.sender] < resourceCost) revert InsufficientResourcesDeposited();

        _depositedResources[msg.sender] -= resourceCost;
        agent1.currentEnergy -= energyCost;
        agent2.currentEnergy -= energyCost;

        uint256 oldEnergy1 = agent1.currentEnergy + energyCost;
        uint256 oldEnergy2 = agent2.currentEnergy + energyCost;
        uint256 oldSkill1 = agent1.currentSkill; // Skill might not change in reproduction
        uint256 oldSkill2 = agent2.currentSkill;

        // INSECURE pseudo-randomness!
        uint256 randomness = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, agentId1, agentId2, currentEpoch, "reproduce")));

        // Success chance example: better chance with higher energy/skill/lower generation/favorable environment
        uint256 successThreshold = (agent1.currentEnergy + agent2.currentEnergy) / 4 + (agent1.currentSkill + agent2.currentSkill) / 10 + environmentalConditions / 5;
        bool success = (randomness % 100) < successThreshold;

        if (success) {
            uint256 newId = _nextAgentId++;
            uint256 newGeneration = Math.max(agent1.generation, agent2.generation) + 1;
            // Simple stat inheritance: average + small random variance
            uint256 newEnergy = (agent1.currentEnergy + agent2.currentEnergy) / 2 + (randomness / 100 % 10) - 5; // Average +/- 5
            uint256 newSkill = (agent1.currentSkill + agent2.currentSkill) / 2 + (randomness / 1000 % 10) - 5; // Average +/- 5
            uint256 newTypeId = agent1.agentTypeId; // Example: Child inherits type from parent1, or maybe a mix, or a new type? Complex!
            // For simplicity, let's say child inherits type of parent1, unless parent types are different - then reproduction might fail or lead to a hybrid type (requires more type logic)

            if (agent1.agentTypeId != agent2.agentTypeId) {
                 // Example rule: Different types cannot reproduce
                 revert AgentsMustBeDifferentTypesForReproduction();
                 // Or handle hybrid logic: maybe create a new agent type on the fly? Too complex for example.
            }


             _agents[newId] = Agent({
                id: newId,
                agentTypeId: newTypeId,
                currentEnergy: newEnergy,
                currentSkill: newSkill,
                generation: newGeneration,
                age: 0
            });

            // ERC721-like minting to caller (owner of parents)
            _agentOwners[newId] = msg.sender;
            _ownerAgentCount[msg.sender]++;
            emit Transfer(address(0), msg.sender, newId);

            emit AgentCreated(newId, msg.sender, newTypeId, currentEpoch); // Child creation event
            emit AgentInteraction(agentId1, agentId2, "ReproduceSuccess", true); // Parents success event
        } else {
            // Reproduction failed, energy consumed
            emit AgentInteraction(agentId1, agentId2, "ReproduceFail", false);
             revert ReproductionFailed(); // Revert the transaction on failure
        }

        // Emit state changes for parents
        emit AgentStateChanged(agentId1, oldEnergy1, agent1.currentEnergy, oldSkill1, agent1.currentSkill);
        emit AgentStateChanged(agentId2, oldEnergy2, agent2.currentEnergy, oldSkill2, agent2.currentSkill);
    }


    // --- ERC721-like Functions (Manual Implementation) ---

    /// @notice Transfers ownership of an agent.
    /// @dev ERC721 `transferFrom`.
    /// @param from The current owner address.
    /// @param to The recipient address.
    /// @param agentId The ID of the agent to transfer.
    function transferFrom(address from, address to, uint256 agentId)
        public
        whenNotPaused
        agentExists(agentId)
        isApprovedOrOwner(agentId) // Ensures msg.sender is owner or approved
    {
        if (_agentOwners[agentId] != from) revert NotAgentOwner(); // Ensure 'from' is the actual owner
        if (to == address(0)) revert InvalidAgentId(); // Cannot transfer to zero address

        // Clear approval for the transferred token
        delete _tokenApprovals[agentId];

        // Update owner balances
        _ownerAgentCount[from]--;
        _ownerAgentCount[to]++;

        // Update owner mapping
        _agentOwners[agentId] = to;

        emit Transfer(from, to, agentId);
    }

    /// @notice Approves a single address to manage an agent.
    /// @dev ERC721 `approve`.
    /// @param to The address to approve.
    /// @param agentId The ID of the agent.
    function approve(address to, uint256 agentId)
        external
        whenNotPaused
        agentExists(agentId)
        isAgentOwner(agentId) // Only owner can approve specific token
    {
        _tokenApprovals[agentId] = to;
        emit Approval(msg.sender, to, agentId);
    }

    /// @notice Approves or revokes an operator for all of the caller's agents.
    /// @dev ERC721 `setApprovalForAll`.
    /// @param operator The address to set as operator.
    /// @param approved True to approve, false to revoke.
    function setApprovalForAll(address operator, bool approved) external whenNotPaused {
        if (operator == msg.sender) revert OwnableUnauthorizedAccount(operator); // Cannot approve self as operator
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }


    // --- Query Functions (View/Pure) ---

    /// @notice Gets the details of a specific agent.
    /// @param agentId The ID of the agent.
    /// @return The Agent struct data.
    function getAgentDetails(uint256 agentId) public view agentExists(agentId) returns (Agent memory) {
        return _agents[agentId];
    }

    /// @notice Gets the details of a specific agent type blueprint.
    /// @param agentTypeId The ID of the agent type.
    /// @return The AgentType struct data.
    function getAgentTypeDetails(uint256 agentTypeId) public view returns (AgentType memory) {
        AgentType memory agentType = _agentTypes[agentTypeId];
        if (bytes(agentType.name).length == 0 && agentTypeId != 0) revert AgentTypeDoesNotExist();
        return agentType;
    }

    /// @notice Gets the current simulation epoch.
    /// @return The current epoch number.
    function getSimulationEpoch() public view returns (uint256) {
        return currentEpoch;
    }

    /// @notice Gets the total number of agents created.
    /// @return The total count of agents.
    function getAgentCount() public view returns (uint256) {
        return _nextAgentId - 1; // _nextAgentId is the ID for the *next* agent
    }

    /// @notice Gets the owner of an agent.
    /// @dev ERC721 `ownerOf`.
    /// @param agentId The ID of the agent.
    /// @return The owner address.
    function getAgentOwner(uint256 agentId) public view agentExists(agentId) returns (address) {
        return _agentOwners[agentId];
    }

    /// @notice Gets the number of agents owned by an address.
    /// @dev ERC721 `balanceOf`.
    /// @param owner The address to check.
    /// @return The number of agents owned.
    function balanceOf(address owner) public view returns (uint256) {
        if (owner == address(0)) revert InvalidAgentId(); // ERC721 standard requires non-zero address
        return _ownerAgentCount[owner];
    }

     /// @notice Gets the approved address for a single agent.
     /// @dev ERC721 `getApproved`.
     /// @param agentId The ID of the agent.
     /// @return The approved address, or address(0) if none.
    function getApproved(uint256 agentId) public view agentExists(agentId) returns (address) {
        return _tokenApprovals[agentId];
    }

     /// @notice Checks if an operator is approved for all of an owner's agents.
     /// @dev ERC721 `isApprovedForAll`.
     /// @param owner The owner address.
     /// @param operator The operator address.
     /// @return True if approved, false otherwise.
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /// @notice Gets the amount of resources an owner is eligible to claim.
    /// @param owner The address to check.
    /// @return The amount of earned resources.
    function getEarnedResources(address owner) public view returns (uint256) {
        return _earnedResources[owner];
    }

    // Helper library for max function, needed for reproduction generation
    library Math {
        function max(uint256 a, uint256 b) internal pure returns (uint256) {
            return a >= b ? a : b;
        }
    }
}
```

**Explanation of Advanced/Creative/Trendy Concepts:**

1.  **Dynamic NFTs (Agents):** Agents are more than static tokens. They have internal state (`currentEnergy`, `currentSkill`, `age`, `generation`) that changes over time based on contract interactions (`rechargeAgentEnergy`, `trainAgentSkill`, `ageAgent`, `agentInteractionCombat`, `agentInteractionCooperate`). This makes them programmable and dynamic on-chain assets.
2.  **On-Chain Simulation/Ecosystem:** The contract simulates a basic environment (`currentEpoch`, `environmentalConditions`) where agents perform actions like harvesting and interacting. This moves beyond simple asset management towards complex state transitions governed by the contract's rules.
3.  **Resource Sink/Faucet:** The `resourceToken` acts as a vital part of the ecosystem. Users spend it (`depositResources`) to power agent actions (`rechargeAgentEnergy`, `trainAgentSkill`, `mutateAgent`, `agentInteractionReproduce`), and agents can produce it (`harvestResources`, `agentInteractionCombat`, `agentInteractionCooperate`), creating a closed-loop economy within the contract.
4.  **Agent Interactions:** The contract includes functions (`agentInteractionCombat`, `agentInteractionCooperate`, `agentInteractionReproduce`) allowing agents to interact with *each other*, affecting the state of *multiple* agents in a single transaction. This is more complex than typical NFT interactions (like trading).
5.  **Probabilistic Outcomes:** Actions like `trainAgentSkill`, `mutateAgent`, `agentInteractionCombat`, `agentInteractionCooperate`, and `harvestResources` incorporate simulated probabilistic outcomes (using simple block data for demonstration, which would need a secure VRF in production). This adds an element of uncertainty and gamification.
6.  **Agent Evolution/Lifecycle:** Agents have `generation` and `age`, which can influence their capabilities or trigger decay (`ageAgent`), and they can potentially create new agents (`agentInteractionReproduce`) or change type/stats (`mutateAgent`), simulating a form of evolution.
7.  **Epoch-based Mechanics:** The `advanceEpoch` function (controlled by owner/time in production) represents global time passing in the simulation, potentially triggering passive effects or changing environmental conditions.
8.  **Manual ERC721-like Implementation:** Instead of inheriting a standard library (like OpenZeppelin) for ERC721, the core ownership and approval logic (`_agentOwners`, `_ownerAgentCount`, `_tokenApprovals`, `_operatorApprovals`, `transferFrom`, `approve`, `setApprovalForAll`, `ownerOf`, `balanceOf`, `getApproved`, `isApprovedForAll`, `Transfer`, `Approval`, `ApprovalForAll` events) is implemented directly within the contract. This fulfills the "don't duplicate any of open source" constraint while providing the necessary NFT ownership features. This is more complex than simple inheritance.
9.  **Custom Errors:** Using `revert CustomError()` for clearer error handling instead of just `require(..., "message")`. (Note: Standard errors like `OwnableUnauthorizedAccount` are also used where appropriate if defining them manually adds clutter).

This contract provides a framework for a complex on-chain simulation or game world where unique, programmable assets (agents) are the core actors, interacting and evolving based on coded rules and resource economics.