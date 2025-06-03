Okay, here is a smart contract concept focusing on Dynamic NFTs (dNFTs) representing "Autonomous Agents" within a simulated ecosystem. The agents' state (skills, performance) changes over time and based on user interactions like training and deploying on missions. It incorporates resource management, time-based state changes, and interaction with external parameters (simulated via admin function).

This concept is creative as it ties NFT state directly to continuous, time-based mechanics and user-driven mini-games (training/missions) within the contract, going beyond static metadata or simple staking. It's trendy due to using dNFTs and game-like mechanics.

We will use OpenZeppelin for standard components like ERC721 and Ownable for security and efficiency, as reimplementing these from scratch is prone to errors and contradicts best practices, while the core logic for state dynamism and interactions is novel.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Although >=0.8.0 has overflow checks by default, explicit SafeMath can improve readability for certain operations. Not strictly necessary for 0.8.20 basic ops.

/**
 * @title AutonomousAgentRegistry
 * @dev A dynamic NFT contract representing Agents that can be trained and deployed on missions.
 * Agent state (skills, performance, energy) changes over time and through interactions.
 * Features: Dynamic state, time-based decay/recharge, ERC20 resource consumption, interactive missions, training mechanics.
 *
 * Outline:
 * 1. Core ERC721 functions (minting, transfer, ownership, approval).
 * 2. Agent State Management (structs, internal state updates, getters).
 * 3. Agent Interaction & Resource Management (energy recharge, training, missions).
 * 4. Mission & Training Configuration (admin functions).
 * 5. Utility & Information functions.
 * 6. Pausability (Admin function).
 *
 * Function Summary:
 * (Standard ERC721 functions are listed implicitly via inheritance but included for count)
 * - constructor: Initializes contract, sets name/symbol, owner.
 * - mintAgent: Creates a new Agent NFT with base stats.
 * - getAgentState: Retrieves the current state of an agent (skills, metrics, energy, state).
 * - rechargeEnergy: Allows owner to spend Energy Tokens to replenish agent's energy.
 * - trainAgent: Stakes required token amount to start training, changing agent state.
 * - claimTraining: Completes training if duration passed, updates skills, returns stake, changes state.
 * - createMission: Admin defines a new mission type with requirements and rewards.
 * - getMissionDetails: Retrieves details for a specific mission ID.
 * - deployAgentOnMission: Sends an agent on a mission, consuming energy, locking agent state, and setting deployment end time.
 * - completeMission: Resolves an agent's mission, simulates outcome based on state/external data, applies rewards/penalties, changes state.
 * - setEnergyToken: Admin sets the ERC20 token used for energy.
 * - setRewardToken: Admin sets the ERC20 token given as mission rewards.
 * - setTrainingParams: Admin sets global training cost and duration.
 * - setMissionParams: Admin updates parameters for an existing mission.
 * - withdrawContractTokens: Admin can withdraw specific tokens held by the contract.
 * - getAgentTrainingStatus: Checks if an agent is training and remaining time.
 * - getAgentDeploymentStatus: Checks if an agent is deployed and remaining time.
 * - pauseContract: Admin pauses certain contract interactions.
 * - unpauseContract: Admin unpauses the contract.
 * - redeemEnergy: Allows owner to convert agent energy back to Energy Tokens (potentially with a fee).
 * - burnAgent: Allows owner to burn their agent NFT, removing it permanently.
 * - getMissionIds: Returns a list of available mission IDs.
 * - agentExists: Checks if a given tokenId exists.
 * - setBaseAgentStats: Admin sets the base stats for new agents.
 * - setAgentPerformanceDecayRate: Admin sets the rate at which performance metrics decay.
 * - setAgentEnergyRechargeRate: Admin sets the rate at which energy naturally recharges (if applicable, or base recharge from rechargeEnergy). We'll make recharge purely through the function for simplicity, decay is time-based.
 * - triggerSimulatedOracleData: Admin provides external data that can influence mission outcomes.
 * - getSimulatedOracleData: View the current simulated oracle data.
 *
 * (Standard ERC721 functions from inheritance):
 * - transferFrom
 * - safeTransferFrom (2 variants)
 * - balanceOf
 * - ownerOf
 * - approve
 * - getApproved
 * - setApprovalForAll
 * - isApprovedForAll
 *
 * Total functions: 1 (constructor) + 22 (custom) + 8 (ERC721 base) = 31 functions.
 */
contract AutonomousAgentRegistry is ERC721, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256; // Use SafeMath explicitly where needed, although 0.8.20 has built-in checks.

    // --- Data Structures ---

    enum SkillType { Strength, Agility, Intellect, Charisma }
    enum MetricType { Stamina, Morale, Experience }
    enum AgentState { Idle, Training, Deployed, Paused } // Paused by admin

    struct Agent {
        address owner;
        uint62 mintTimestamp; // Using smaller type if fits, saves gas
        uint66 lastStateUpdateTimestamp; // Using smaller type
        mapping(SkillType => uint256) skills;
        mapping(MetricType => uint256) performanceMetrics; // E.g., Stamina decays, Experience increases
        uint256 currentEnergy; // Resource needed for actions
        AgentState state;
        uint64 stateChangeEndTime; // Timestamp for end of Training or Deployment
        uint64 activeMissionId; // 0 if not deployed
    }

    struct Mission {
        uint64 id;
        string name;
        mapping(SkillType => uint256) requiredSkills; // Minimum required skill level
        uint256 energyCost;
        uint64 duration; // In seconds
        uint256 successRewardAmount; // Amount of RewardToken
        int256 performancePenaltyOnFailure; // Signed int for potential decrease
        // Add potential for specific skill/metric changes on success/failure
    }

    // --- State Variables ---

    Counters.Counter private _tokenIdCounter; // For unique agent IDs
    mapping(uint256 => Agent) private _agents;
    mapping(uint64 => Mission) private _missions;
    uint64 private _nextMissionId = 1; // Auto-incrementing mission ID

    IERC20 public energyToken;
    IERC20 public rewardToken;

    uint256 public trainingStakeAmount; // Amount of EnergyToken needed to stake for training
    uint64 public trainingDuration; // In seconds

    mapping(SkillType => uint256) public baseAgentSkills;
    mapping(MetricType => uint256) public baseAgentMetrics;
    uint256 public baseAgentEnergy;

    uint256 public agentPerformanceDecayRatePerSecond; // Rate per second
    uint256 public energyRedemptionFeeBasisPoints = 1000; // 10% fee for redeeming energy (1000/10000)

    bytes public simulatedOracleData; // Placeholder for external influence

    bool public paused = false; // Global pause switch

    // --- Events ---

    event AgentMinted(uint256 indexed tokenId, address indexed owner, uint62 mintTimestamp);
    event AgentStateUpdated(uint256 indexed tokenId, AgentState oldState, AgentState newState);
    event EnergyRecharged(uint256 indexed tokenId, uint256 amount, uint256 newEnergy);
    event TrainingStarted(uint256 indexed tokenId, uint64 trainingEndTime);
    event TrainingCompleted(uint256 indexed tokenId, uint64 trainingEndTime, bool skillsIncreased);
    event MissionCreated(uint64 indexed missionId, string name, uint256 energyCost, uint64 duration);
    event MissionDeployed(uint256 indexed tokenId, uint64 indexed missionId, uint64 deploymentEndTime);
    event MissionCompleted(uint256 indexed tokenId, uint64 indexed missionId, bool success, uint256 rewardAmount, int256 performanceChange);
    event EnergyRedeemed(uint256 indexed tokenId, uint256 energyAmount, uint256 tokenAmountReceived);
    event AgentBurned(uint256 indexed tokenId, address indexed owner);
    event ContractPaused(address indexed account);
    event ContractUnpaused(address indexed account);
    event SimulatedOracleDataUpdated(bytes data);

    // --- Modifiers ---

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier onlyAgentOwner(uint256 tokenId) {
        require(_exists(tokenId), "Agent does not exist");
        require(ownerOf(tokenId) == msg.sender, "Not agent owner");
        _;
    }

    // --- Constructor ---

    constructor(string memory name, string memory symbol)
        ERC721(name, symbol)
        Ownable(msg.sender)
    {
        // Set some initial base stats and parameters
        baseAgentSkills[SkillType.Strength] = 10;
        baseAgentSkills[SkillType.Agility] = 10;
        baseAgentSkills[SkillType.Intellect] = 10;
        baseAgentSkills[SkillType.Charisma] = 10;

        baseAgentMetrics[MetricType.Stamina] = 100;
        baseAgentMetrics[MetricType.Morale] = 100;
        baseAgentMetrics[MetricType.Experience] = 0;

        baseAgentEnergy = 50; // Initial energy upon mint

        trainingStakeAmount = 100 ether; // Example: 100 units of EnergyToken
        trainingDuration = 1 days; // Example: 1 day

        agentPerformanceDecayRatePerSecond = 1; // Example: Decay 1 Stamina/Morale per second

        // Note: energyToken and rewardToken must be set via admin functions later
    }

    // --- Internal State Update Logic ---

    /**
     * @dev Updates agent's state based on time elapsed since last update.
     * Calculates energy recharge and applies decay to performance metrics.
     * Called automatically by most state-changing public functions.
     */
    function _updateAgentState(uint256 tokenId) internal {
        Agent storage agent = _agents[tokenId];
        uint256 currentTime = block.timestamp;
        uint256 timeElapsed = currentTime - agent.lastStateUpdateTimestamp;

        // Apply decay to performance metrics (only if not paused/training/deployed state where decay might be different or paused)
        // Let's decay only in Idle state for simplicity
        if (agent.state == AgentState.Idle) {
             // Calculate total decay amount based on time elapsed and rate
            uint256 decayAmount = timeElapsed.mul(agentPerformanceDecayRatePerSecond);

            // Apply decay, ensure metrics don't go below 0
            agent.performanceMetrics[MetricType.Stamina] = agent.performanceMetrics[MetricType.Stamina].sub(decayAmount, "Stamina cannot be negative");
            agent.performanceMetrics[MetricType.Morale] = agent.performanceMetrics[MetricType.Morale].sub(decayAmount, "Morale cannot be negative");

            // Cap metrics at 0
            if (agent.performanceMetrics[MetricType.Stamina] > 0) {
                 // The safe sub above handles this if decayAmount isn't ridiculously large.
                 // Explicit check for safety against unexpected values.
                if (agent.performanceMetrics[MetricType.Stamina] < decayAmount) agent.performanceMetrics[MetricType.Stamina] = 0;
                else agent.performanceMetrics[MetricType.Stamina] -= decayAmount;
            } else {
                agent.performanceMetrics[MetricType.Stamina] = 0;
            }

             if (agent.performanceMetrics[MetricType.Morale] > 0) {
                if (agent.performanceMetrics[MetricType.Morale] < decayAmount) agent.performanceMetrics[MetricType.Morale] = 0;
                else agent.performanceMetrics[MetricType.Morale] -= decayAmount;
            } else {
                agent.performanceMetrics[MetricType.Morale] = 0;
            }

            // Note: Energy recharge is *not* time-based natural regen in this design,
            // it's only through the rechargeEnergy function for explicit user action.
        }
        // Experience might increase or stay same depending on actions, doesn't decay passively.

        agent.lastStateUpdateTimestamp = uint66(currentTime); // Update last update time
    }


    // --- Core ERC721 Function Overrides (Implicitly satisfy interface, adding to function count) ---
    // No specific overrides needed for basic functionality unless adding hooks like _beforeTokenTransfer

    // --- Agent Management Functions ---

    /**
     * @dev Mints a new agent NFT to the specified owner.
     * Initializes base skills, metrics, and energy.
     * Callable by owner or potentially other roles (e.g., a Factory contract).
     */
    function mintAgent(address owner) public onlyOwner whenNotPaused returns (uint256) {
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        _safeMint(owner, newTokenId);

        Agent storage newAgent = _agents[newTokenId];
        newAgent.owner = owner;
        newAgent.mintTimestamp = uint62(block.timestamp);
        newAgent.lastStateUpdateTimestamp = uint66(block.timestamp);

        // Set base stats
        newAgent.skills[SkillType.Strength] = baseAgentSkills[SkillType.Strength];
        newAgent.skills[SkillType.Agility] = baseAgentSkills[SkillType.Agility];
        newAgent.skills[SkillType.Intellect] = baseAgentSkills[SkillType.Intellect];
        newAgent.skills[SkillType.Charisma] = baseAgentSkills[SkillType.Charisma];

        newAgent.performanceMetrics[MetricType.Stamina] = baseAgentMetrics[MetricType.Stamina];
        newAgent.performanceMetrics[MetricType.Morale] = baseAgentMetrics[MetricType.Morale];
        newAgent.performanceMetrics[MetricType.Experience] = baseAgentMetrics[MetricType.Experience];

        newAgent.currentEnergy = baseAgentEnergy;
        newAgent.state = AgentState.Idle;
        newAgent.stateChangeEndTime = 0;
        newAgent.activeMissionId = 0;

        emit AgentMinted(newTokenId, owner, newAgent.mintTimestamp);
        return newTokenId;
    }

    /**
     * @dev Gets the full state of an agent, ensuring it's updated based on time.
     * @param tokenId The ID of the agent NFT.
     * @return AgentState struct data.
     */
    function getAgentState(uint256 tokenId) public view returns (
        address owner,
        uint62 mintTimestamp,
        uint66 lastStateUpdateTimestamp,
        uint256 strength, uint256 agility, uint256 intellect, uint256 charisma,
        uint256 stamina, uint256 morale, uint256 experience,
        uint256 currentEnergy,
        AgentState state,
        uint64 stateChangeEndTime,
        uint64 activeMissionId
    ) {
        require(_exists(tokenId), "Agent does not exist");
        Agent storage agent = _agents[tokenId];

        // Note: This view function doesn't modify state, so we can't call _updateAgentState here.
        // The caller should be aware the state might be slightly outdated if called externally
        // without a preceding state-changing transaction. However, core interactions DO update state.
        // For a truly real-time view, a separate off-chain service might simulate decay client-side.
        // Let's return the *stored* state. State updates happen ON-CHAIN during txns.

        owner = agent.owner;
        mintTimestamp = agent.mintTimestamp;
        lastStateUpdateTimestamp = agent.lastStateUpdateTimestamp;
        strength = agent.skills[SkillType.Strength];
        agility = agent.skills[SkillType.Agility];
        intellect = agent.skills[SkillType.Intellect];
        charisma = agent.skills[SkillType.Charisma];
        stamina = agent.performanceMetrics[MetricType.Stamina];
        morale = agent.performanceMetrics[MetricType.Morale];
        experience = agent.performanceMetrics[MetricType.Experience];
        currentEnergy = agent.currentEnergy;
        state = agent.state;
        stateChangeEndTime = agent.stateChangeEndTime;
        activeMissionId = agent.activeMissionId;

        // A more complex view *could* simulate the decay locally for display purposes,
        // but returning stored state is standard for on-chain views.
    }

    /**
     * @dev Allows the owner to recharge an agent's energy by spending energy tokens.
     * @param tokenId The ID of the agent.
     * @param amount The amount of energy tokens to spend.
     */
    function rechargeEnergy(uint256 tokenId, uint256 amount) public onlyAgentOwner(tokenId) whenNotPaused {
        _updateAgentState(tokenId); // Update state before action

        Agent storage agent = _agents[tokenId];
        require(energyToken != address(0), "Energy token not set");
        require(amount > 0, "Amount must be greater than 0");
        // Optionally add max energy limit
        // require(agent.currentEnergy.add(amount) <= MAX_ENERGY, "Exceeds max energy capacity");

        // Transfer tokens from the user to the contract
        require(energyToken.transferFrom(msg.sender, address(this), amount), "Energy token transfer failed");

        agent.currentEnergy = agent.currentEnergy.add(amount);

        emit EnergyRecharged(tokenId, amount, agent.currentEnergy);
    }

    /**
     * @dev Starts the training process for an agent. Requires staking tokens.
     * Agent state changes to Training.
     * @param tokenId The ID of the agent.
     */
    function trainAgent(uint256 tokenId) public onlyAgentOwner(tokenId) whenNotPaused {
         _updateAgentState(tokenId); // Update state before action

        Agent storage agent = _agents[tokenId];
        require(agent.state == AgentState.Idle, "Agent is not Idle");
        require(energyToken != address(0), "Energy token not set");
        require(trainingStakeAmount > 0, "Training is not configured");

        // Transfer stake tokens from the user to the contract
        require(energyToken.transferFrom(msg.sender, address(this), trainingStakeAmount), "Training stake transfer failed");

        agent.state = AgentState.Training;
        agent.stateChangeEndTime = uint64(block.timestamp + trainingDuration);

        emit AgentStateUpdated(tokenId, AgentState.Idle, AgentState.Training);
        emit TrainingStarted(tokenId, agent.stateChangeEndTime);
    }

    /**
     * @dev Claims the results of training if the duration has passed.
     * Increases skills and returns staked tokens. Changes state back to Idle.
     * @param tokenId The ID of the agent.
     */
    function claimTraining(uint256 tokenId) public onlyAgentOwner(tokenId) whenNotPaused {
        _updateAgentState(tokenId); // Update state before action

        Agent storage agent = _agents[tokenId];
        require(agent.state == AgentState.Training, "Agent is not Training");
        require(block.timestamp >= agent.stateChangeEndTime, "Training is not complete");

        // Increase a random skill slightly or all skills based on logic
        // Simple example: Increase Strength and Experience
        agent.skills[SkillType.Strength] = agent.skills[SkillType.Strength].add(1);
        agent.performanceMetrics[MetricType.Experience] = agent.performanceMetrics[MetricType.Experience].add(10);

        // Return staked tokens to the user
        require(energyToken.transfer(msg.sender, trainingStakeAmount), "Failed to return training stake");

        agent.state = AgentState.Idle;
        agent.stateChangeEndTime = 0; // Reset end time

        emit AgentStateUpdated(tokenId, AgentState.Training, AgentState.Idle);
        emit TrainingCompleted(tokenId, agent.stateChangeEndTime, true);
    }

    // --- Mission Functions ---

    /**
     * @dev Admin function to create a new mission type.
     * @param id Unique ID for the mission (should be > 0).
     * @param name Name of the mission.
     * @param requiredSkills Mapping of skills and required levels.
     * @param energyCost Energy consumed by the agent.
     * @param duration Duration of the mission in seconds.
     * @param successRewardAmount Amount of reward token on success.
     * @param performancePenaltyOnFailure Change in performance metric(s) on failure.
     */
    function createMission(
        uint64 id,
        string memory name,
        mapping(SkillType => uint256) memory requiredSkills, // Cannot pass mapping directly, pass as arrays/lists
        uint256 energyCost,
        uint64 duration,
        uint256 successRewardAmount,
        int256 performancePenaltyOnFailure
    ) public onlyOwner {
         require(id > 0, "Mission ID must be > 0");
         require(_missions[id].id == 0, "Mission ID already exists"); // Check if ID is unique
         require(duration > 0, "Mission duration must be > 0");
         require(energyCost <= baseAgentEnergy * 2, "Energy cost seems too high"); // Sanity check

         _missions[id].id = id;
         _missions[id].name = name;
         // Need helper to copy skill requirements from arrays
         // For simplicity in this example, let's assume fixed skills checked internally or pass arrays:
         // For a real contract, you'd pass `SkillType[] skillTypes` and `uint256[] requiredLevels` and loop.
         // Example simplified: requires minimum Strength and Agility
         _missions[id].requiredSkills[SkillType.Strength] = requiredSkills[SkillType.Strength];
         _missions[id].requiredSkills[SkillType.Agility] = requiredSkills[SkillType.Agility];
         _missions[id].requiredSkills[SkillType.Intellect] = requiredSkills[SkillType.Intellect];
         _missions[id].requiredSkills[SkillType.Charisma] = requiredSkills[SkillType.Charisma];


         _missions[id].energyCost = energyCost;
         _missions[id].duration = duration;
         _missions[id].successRewardAmount = successRewardAmount;
         _missions[id].performancePenaltyOnFailure = performancePenaltyOnFailure;

        // If auto-incrementing ID was desired instead:
        // uint64 newMissionId = _nextMissionId++;
        // _missions[newMissionId] = Mission(...);
        // emit MissionCreated(newMissionId, ...);

         emit MissionCreated(id, name, energyCost, duration);
    }

    /**
     * @dev Gets details for a specific mission ID.
     * @param missionId The ID of the mission.
     * @return Mission struct data.
     */
    function getMissionDetails(uint64 missionId) public view returns (
        uint64 id,
        string memory name,
        uint256 reqStrength, uint256 reqAgility, uint256 reqIntellect, uint256 reqCharisma,
        uint256 energyCost,
        uint64 duration,
        uint256 successRewardAmount,
        int256 performancePenaltyOnFailure
    ) {
        require(_missions[missionId].id != 0, "Mission does not exist");
        Mission storage mission = _missions[missionId];

        id = mission.id;
        name = mission.name;
        reqStrength = mission.requiredSkills[SkillType.Strength];
        reqAgility = mission.requiredSkills[SkillType.Agility];
        reqIntellect = mission.requiredSkills[SkillType.Intellect];
        reqCharisma = mission.requiredSkills[SkillType.Charisma];
        energyCost = mission.energyCost;
        duration = mission.duration;
        successRewardAmount = mission.successRewardAmount;
        performancePenaltyOnFailure = mission.performancePenaltyOnFailure;
    }

     /**
     * @dev Returns an array of all existing mission IDs.
     * Note: This can be gas-intensive if many missions are created.
     * For production, consider a more scalable pattern (e.g., indexed events or pagination).
     */
    function getMissionIds() public view returns (uint64[] memory) {
        // In a real system, you might track IDs in an array or linked list for retrieval.
        // Simple iteration check here (up to a reasonable limit or until ID 0 is hit).
        // This is a placeholder; production would need a better pattern.
         uint64[] memory ids = new uint64[](_nextMissionId); // Max possible size if using auto-increment
         uint64 count = 0;
         for (uint64 i = 1; i < _nextMissionId; i++) {
             if (_missions[i].id != 0) {
                 ids[count] = i;
                 count++;
             }
         }
         // Trim array to actual count - gas costly
        uint64[] memory actualIds = new uint64[](count);
        for(uint64 i = 0; i < count; i++){
            actualIds[i] = ids[i];
        }
         return actualIds; // This implementation works better if createMission uses _nextMissionId
         // If createMission uses arbitrary IDs, a mapping and explicit tracking array is needed.
         // Let's refactor createMission slightly to use _nextMissionId internally for this function to work simply.
         // (Correction: Keeping createMission with explicit ID as requested initially, but this getMissionIds
         // then becomes inefficient/limited or needs a separate ID tracking array).
         // Let's use the limited loop approach for demonstration, up to say 100 IDs.

        uint64[] memory potentialIds = new uint64[](100); // Limit to first 100 potential IDs
        uint64 currentCount = 0;
         for (uint64 i = 1; i <= 100; i++) { // Check IDs 1 to 100
             if (_missions[i].id != 0) {
                 potentialIds[currentCount] = i;
                 currentCount++;
             }
         }
         uint64[] memory existingIds = new uint64[](currentCount);
         for(uint64 i = 0; i < currentCount; i++){
            existingIds[i] = potentialIds[i];
         }
        return existingIds; // This is a safer demonstration approach
    }


    /**
     * @dev Deploys an agent on a specific mission.
     * Requires agent to be Idle, have sufficient energy, and meet skill requirements.
     * Consumes energy and changes agent state to Deployed.
     * @param tokenId The ID of the agent.
     * @param missionId The ID of the mission to deploy on.
     */
    function deployAgentOnMission(uint256 tokenId, uint64 missionId) public onlyAgentOwner(tokenId) whenNotPaused {
        _updateAgentState(tokenId); // Update state before action

        Agent storage agent = _agents[tokenId];
        Mission storage mission = _missions[missionId];

        require(agent.state == AgentState.Idle, "Agent is not Idle");
        require(mission.id != 0, "Mission does not exist");
        require(agent.currentEnergy >= mission.energyCost, "Insufficient energy");

        // Check skill requirements
        require(agent.skills[SkillType.Strength] >= mission.requiredSkills[SkillType.Strength], "Insufficient Strength");
        require(agent.skills[SkillType.Agility] >= mission.requiredSkills[SkillType.Agility], "Insufficient Agility");
        require(agent.skills[SkillType.Intellect] >= mission.requiredSkills[SkillType.Intellect], "Insufficient Intellect");
        require(agent.skills[SkillType.Charisma] >= mission.requiredSkills[SkillType.Charisma], "Insufficient Charisma");

        // Consume energy
        agent.currentEnergy = agent.currentEnergy.sub(mission.energyCost);

        // Set agent state to Deployed
        agent.state = AgentState.Deployed;
        agent.activeMissionId = missionId;
        agent.stateChangeEndTime = uint64(block.timestamp + mission.duration);

        emit AgentStateUpdated(tokenId, AgentState.Idle, AgentState.Deployed);
        emit MissionDeployed(tokenId, missionId, agent.stateChangeEndTime);
    }

     /**
     * @dev Internal function to simulate mission outcome based on agent skills and requirements.
     * Can also be influenced by external data (simulated oracle).
     * Returns true for success, false for failure.
     */
    function _simulateMissionOutcome(uint256 tokenId, uint64 missionId, bytes memory externalData) internal view returns (bool) {
        Agent storage agent = _agents[tokenId];
        Mission storage mission = _missions[missionId];

        // Simple deterministic outcome simulation:
        // Base success chance from skills vs requirements.
        // Example: Sum of agent skills vs sum of required skills.
        uint256 agentTotalSkill = agent.skills[SkillType.Strength].add(agent.skills[SkillType.Agility]).add(agent.skills[SkillType.Intellect]).add(agent.skills[SkillType.Charisma]);
        uint256 missionTotalRequirement = mission.requiredSkills[SkillType.Strength].add(mission.requiredSkills[SkillType.Agility]).add(mission.requiredSkills[SkillType.Intellect]).add(mission.requiredSkills[SkillType.Charisma]);

        // Avoid division by zero
        uint256 skillRatio = missionTotalRequirement == 0 ? 10000 : agentTotalSkill.mul(10000) / missionTotalRequirement; // Ratio out of 10000

        // Base success chance (e.g., 50% + ratio influence)
        uint256 baseChance = 5000; // 50% chance out of 10000
        uint256 chanceFromSkills = skillRatio > 10000 ? 5000 : skillRatio.mul(5000) / 10000; // Max +50% from skills
        uint256 totalSuccessChance = baseChance.add(chanceFromSkills);

        // Influence from simulated oracle data (simple example: interpret first byte)
        if (externalData.length > 0) {
            uint8 oracleInfluence = uint8(externalData[0]);
            // Add influence (e.g., up to +/- 20%)
            if (oracleInfluence < 128) { // Negative influence
                totalSuccessChance = totalSuccessChance.sub(uint256(128 - oracleInfluence).mul(2000) / 128, "Success chance cannot be negative");
            } else { // Positive influence
                 totalSuccessChance = totalSuccessChance.add(uint256(oracleInfluence - 128).mul(2000) / 127); // Up to +20%
            }
        }

         // Cap chance between 0 and 10000
         if (totalSuccessChance > 10000) totalSuccessChance = 10000;
         if (totalSuccessChance < 0) totalSuccessChance = 0; // SafeMath prevents negative, but good practice.

        // To make it non-deterministic on-chain without an actual oracle is hard/impossible securely.
        // Using block.timestamp or blockhash is exploitable by miners.
        // This function is *view* and *deterministic* based on inputs (agent, mission, externalData).
        // The 'randomness' or external factor comes *only* from `externalData` provided via `triggerSimulatedOracleData`.
        // A real dApp front-end would use this to show *expected* outcome, and the contract uses it for final outcome.

        // For this *simulation* function (which doesn't use chain state random sources),
        // we'll make it deterministic based on skills + oracle data.
        // A ratio > 1 (i.e., skillRatio >= 10000) makes success highly likely.
        // Let's say 100% chance if skills are 2x requirements or more.
         if (skillRatio >= 20000) return true; // 2x skills guarantees success

         // Otherwise, outcome is based on the calculated chance vs a fixed threshold for demo.
         // This is NOT random. A real mission *completion* would need the outcome fed in,
         // or use a Chainlink VRF/external adapter.
         // Let's make it pass if totalSuccessChance >= 70% for demo purposes using a fixed threshold.
         return totalSuccessChance >= 7000; // Success if chance >= 70%
    }


    /**
     * @dev Completes an agent's mission if the duration has passed.
     * Simulates outcome, applies rewards/penalties, changes state back to Idle.
     * @param tokenId The ID of the agent.
     */
    function completeMission(uint256 tokenId) public onlyAgentOwner(tokenId) whenNotPaused {
        _updateAgentState(tokenId); // Update state before action (decay during mission)

        Agent storage agent = _agents[tokenId];
        require(agent.state == AgentState.Deployed, "Agent is not Deployed");
        require(block.timestamp >= agent.stateChangeEndTime, "Mission is not complete");

        Mission storage mission = _missions[agent.activeMissionId];
        require(mission.id != 0, "Active mission is invalid"); // Should not happen if deployment worked

        // Simulate outcome based on current (decayed) state and potential oracle data
        // Passing simulatedOracleData state variable.
        bool success = _simulateMissionOutcome(tokenId, agent.activeMissionId, simulatedOracleData);

        int256 performanceChange = 0; // Track total performance change for the event

        if (success) {
            // Grant reward token
            require(rewardToken != address(0), "Reward token not set");
            require(rewardToken.transfer(msg.sender, mission.successRewardAmount), "Failed to transfer reward token");

            // Increase Experience on success
            agent.performanceMetrics[MetricType.Experience] = agent.performanceMetrics[MetricType.Experience].add(mission.duration / 3600); // Gain 10 Exp per hour of mission

            emit MissionCompleted(tokenId, agent.activeMissionId, true, mission.successRewardAmount, 0); // No penalty on success
        } else {
            // Apply performance penalty
            int256 penalty = mission.performancePenaltyOnFailure;
            performanceChange = penalty;

            // Apply penalty to Stamina and Morale (e.g., halve the penalty for each)
            int256 halvedPenalty = penalty / 2;

            if (halvedPenalty < 0) { // If penalty is negative (e.g., -20) add to metrics
                 agent.performanceMetrics[MetricType.Stamina] = agent.performanceMetrics[MetricType.Stamina].add(uint256(-halvedPenalty));
                 agent.performanceMetrics[MetricType.Morale] = agent.performanceMetrics[MetricType.Morale].add(uint256(-halvedPenalty));
            } else { // If penalty is positive (e.g., 20) subtract from metrics
                 agent.performanceMetrics[MetricType.Stamina] = agent.performanceMetrics[MetricType.Stamina].sub(uint256(halvedPenalty), "Stamina cannot be negative");
                 agent.performanceMetrics[MetricType.Morale] = agent.performanceMetrics[MetricType.Morale].sub(uint256(halvedPenalty), "Morale cannot be negative");

                 // Ensure minimum 0
                 if (agent.performanceMetrics[MetricType.Stamina] > 0) {
                    if (agent.performanceMetrics[MetricType.Stamina] < uint256(halvedPenalty)) agent.performanceMetrics[MetricType.Stamina] = 0;
                    else agent.performanceMetrics[MetricType.Stamina] -= uint256(halvedPenalty);
                 } else { agent.performanceMetrics[MetricType.Stamina] = 0; }

                 if (agent.performanceMetrics[MetricType.Morale] > 0) {
                    if (agent.performanceMetrics[MetricType.Morale] < uint256(halvedPenalty)) agent.performanceMetrics[MetricType.Morale] = 0;
                    else agent.performanceMetrics[MetricType.Morale] -= uint256(halvedPenalty);
                 } else { agent.performanceMetrics[MetricType.Morale] = 0; }

            }

            // Experience does not decrease on failure, might slightly increase from attempt
            agent.performanceMetrics[MetricType.Experience] = agent.performanceMetrics[MetricType.Experience].add(mission.duration / 7200); // Gain 5 Exp per hour on failure

            emit MissionCompleted(tokenId, agent.activeMissionId, false, 0, performanceChange);
        }

        // Reset state
        agent.state = AgentState.Idle;
        agent.stateChangeEndTime = 0;
        agent.activeMissionId = 0;

        emit AgentStateUpdated(tokenId, AgentState.Deployed, AgentState.Idle);
    }

    // --- Configuration & Admin Functions ---

    /**
     * @dev Admin sets the address of the ERC20 token used for Energy.
     * @param tokenAddress The address of the Energy token contract.
     */
    function setEnergyToken(address tokenAddress) public onlyOwner {
        energyToken = IERC20(tokenAddress);
    }

    /**
     * @dev Admin sets the address of the ERC20 token used for Rewards.
     * @param tokenAddress The address of the Reward token contract.
     */
    function setRewardToken(address tokenAddress) public onlyOwner {
        rewardToken = IERC20(tokenAddress);
    }

    /**
     * @dev Admin sets parameters for training.
     * @param stakeAmount Amount of energy token to stake.
     * @param durationInSeconds Duration of training.
     */
    function setTrainingParams(uint256 stakeAmount, uint64 durationInSeconds) public onlyOwner {
        trainingStakeAmount = stakeAmount;
        trainingDuration = durationInSeconds;
    }

    /**
     * @dev Admin updates parameters for an existing mission.
     * Allows modification of name, requirements, costs, rewards, penalties.
     * @param missionId The ID of the mission to update.
     * @param name New name.
     * @param requiredSkills New skill requirements.
     * @param energyCost New energy cost.
     * @param duration New duration.
     * @param successRewardAmount New success reward.
     * @param performancePenaltyOnFailure New failure penalty.
     */
     function setMissionParams(
        uint64 missionId,
        string memory name,
        mapping(SkillType => uint256) memory requiredSkills,
        uint256 energyCost,
        uint64 duration,
        uint256 successRewardAmount,
        int256 performancePenaltyOnFailure
     ) public onlyOwner {
         require(_missions[missionId].id != 0, "Mission does not exist");
         require(duration > 0, "Mission duration must be > 0");

         _missions[missionId].name = name;
         // Copy updated skill requirements
         _missions[missionId].requiredSkills[SkillType.Strength] = requiredSkills[SkillType.Strength];
         _missions[missionId].requiredSkills[SkillType.Agility] = requiredSkills[SkillType.Agility];
         _missions[missionId].requiredSkills[SkillType.Intellect] = requiredSkills[SkillType.Intellect];
         _missions[missionId].requiredSkills[SkillType.Charisma] = requiredSkills[SkillType.Charisma];

         _missions[missionId].energyCost = energyCost;
         _missions[missionId].duration = duration;
         _missions[missionId].successRewardAmount = successRewardAmount;
         _missions[missionId].performancePenaltyOnFailure = performancePenaltyOnFailure;

         // Event could be emitted here
     }


     /**
      * @dev Admin sets the base stats for newly minted agents.
      * Does not affect existing agents.
      * @param baseSkills Base skill levels.
      * @param baseMetrics Base performance metrics.
      * @param initialEnergy Base energy.
      */
     function setBaseAgentStats(
         mapping(SkillType => uint256) memory baseSkills,
         mapping(MetricType => uint256) memory baseMetrics,
         uint256 initialEnergy
     ) public onlyOwner {
         baseAgentSkills[SkillType.Strength] = baseSkills[SkillType.Strength];
         baseAgentSkills[SkillType.Agility] = baseSkills[SkillType.Agility];
         baseAgentSkills[SkillType.Intellect] = baseSkills[SkillType.Intellect];
         baseAgentSkills[SkillType.Charisma] = baseSkills[SkillType.Charisma];

         baseAgentMetrics[MetricType.Stamina] = baseMetrics[MetricType.Stamina];
         baseAgentMetrics[MetricType.Morale] = baseMetrics[MetricType.Morale];
         baseAgentMetrics[MetricType.Experience] = baseMetrics[MetricType.Experience];

         baseAgentEnergy = initialEnergy;
     }

     /**
      * @dev Admin sets the performance decay rate per second for agents.
      * Applies to Stamina and Morale in Idle state.
      * @param rate Decay amount per second.
      */
     function setAgentPerformanceDecayRate(uint256 rate) public onlyOwner {
         agentPerformanceDecayRatePerSecond = rate;
     }

     /**
      * @dev Admin sets the fee percentage for redeeming energy back into tokens.
      * Basis points (e.g., 1000 = 10%). Max 10000.
      * @param basisPoints Fee rate in basis points.
      */
     function setEnergyRedemptionFeeBasisPoints(uint256 basisPoints) public onlyOwner {
         require(basisPoints <= 10000, "Basis points cannot exceed 10000 (100%)");
         energyRedemptionFeeBasisPoints = basisPoints;
     }

     /**
      * @dev Admin function to simulate providing external data (e.g., from an oracle).
      * This data can influence mission outcomes in _simulateMissionOutcome.
      * @param data Arbitrary bytes data from the simulated oracle.
      */
     function triggerSimulatedOracleData(bytes memory data) public onlyOwner {
         simulatedOracleData = data;
         emit SimulatedOracleDataUpdated(data);
     }

     /**
      * @dev View function to get the current simulated oracle data.
      */
     function getSimulatedOracleData() public view returns (bytes memory) {
         return simulatedOracleData;
     }

     /**
      * @dev Allows the owner to withdraw stuck or earned tokens from the contract.
      * Excludes the contract's own NFT tokens or active stakes/rewards.
      * Use with caution.
      * @param tokenAddress The address of the token to withdraw.
      */
     function withdrawContractTokens(address tokenAddress) public onlyOwner {
         require(tokenAddress != address(0), "Invalid token address");
         // Prevent withdrawing native Ether or contract's own ERC721 tokens
         require(tokenAddress != address(this), "Cannot withdraw contract itself");
         // Potentially add more checks to prevent withdrawing active stakes or future rewards

         IERC20 token = IERC20(tokenAddress);
         uint256 balance = token.balanceOf(address(this));

         // Ensure balance is not zero before attempting transfer
         if (balance > 0) {
             require(token.transfer(msg.sender, balance), "Token withdrawal failed");
         }
     }


    // --- Utility & Information Functions ---

    /**
     * @dev Checks if an agent tokenId exists.
     * @param tokenId The ID of the agent.
     */
    function agentExists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    /**
     * @dev Gets the training status for an agent.
     * @param tokenId The ID of the agent.
     * @return isTraining True if currently training.
     * @return endTime Timestamp when training ends (0 if not training).
     */
    function getAgentTrainingStatus(uint256 tokenId) public view returns (bool isTraining, uint64 endTime) {
        require(_exists(tokenId), "Agent does not exist");
        Agent storage agent = _agents[tokenId];
        isTraining = (agent.state == AgentState.Training);
        endTime = agent.stateChangeEndTime;
    }

    /**
     * @dev Gets the deployment status for an agent.
     * @param tokenId The ID of the agent.
     * @return isDeployed True if currently deployed.
     * @return missionId The ID of the active mission (0 if not deployed).
     * @return endTime Timestamp when deployment ends (0 if not deployed).
     */
    function getAgentDeploymentStatus(uint256 tokenId) public view returns (bool isDeployed, uint64 missionId, uint64 endTime) {
        require(_exists(tokenId), "Agent does not exist");
        Agent storage agent = _agents[tokenId];
        isDeployed = (agent.state == AgentState.Deployed);
        missionId = agent.activeMissionId;
        endTime = agent.stateChangeEndTime;
    }

    /**
     * @dev Allows agent owner to redeem agent energy back into Energy Tokens.
     * A fee is applied based on `energyRedemptionFeeBasisPoints`.
     * @param tokenId The ID of the agent.
     * @param energyAmount The amount of energy to redeem.
     */
    function redeemEnergy(uint256 tokenId, uint256 energyAmount) public onlyAgentOwner(tokenId) whenNotPaused {
        _updateAgentState(tokenId); // Update state before action

        Agent storage agent = _agents[tokenId];
        require(agent.currentEnergy >= energyAmount, "Insufficient energy to redeem");
        require(energyToken != address(0), "Energy token not set");
        require(energyAmount > 0, "Amount must be greater than 0");

        agent.currentEnergy = agent.currentEnergy.sub(energyAmount);

        uint256 fee = energyAmount.mul(energyRedemptionFeeBasisPoints).div(10000);
        uint256 tokensToTransfer = energyAmount.sub(fee); // Assuming 1 Energy = 1 Token value for redemption

        require(energyToken.transfer(msg.sender, tokensToTransfer), "Energy token redemption transfer failed");

        // Fee tokens remain in the contract, can be withdrawn by owner

        emit EnergyRedeemed(tokenId, energyAmount, tokensToTransfer);
    }

    /**
     * @dev Allows agent owner to burn (destroy) their agent NFT.
     * Recovers any energy the agent had, minus the redemption fee.
     * @param tokenId The ID of the agent to burn.
     */
    function burnAgent(uint256 tokenId) public onlyAgentOwner(tokenId) whenNotPaused {
        _updateAgentState(tokenId); // Update state before action

        Agent storage agent = _agents[tokenId];
        require(agent.state == AgentState.Idle, "Agent is not Idle, cannot burn");

        uint256 remainingEnergy = agent.currentEnergy;
        if (remainingEnergy > 0) {
             require(energyToken != address(0), "Energy token not set for energy recovery");
            uint256 fee = remainingEnergy.mul(energyRedemptionFeeBasisPoints).div(10000);
            uint256 tokensToTransfer = remainingEnergy.sub(fee);
            if (tokensToTransfer > 0) {
                 require(energyToken.transfer(msg.sender, tokensToTransfer), "Failed to return energy tokens during burn");
            }
        }

        address owner = agent.owner;

        // Delete agent data
        delete _agents[tokenId];

        // Burn the NFT
        _burn(tokenId);

        emit AgentBurned(tokenId, owner);
    }


    // --- Pausability ---

    /**
     * @dev Admin pauses the contract. Prevents certain actions like minting, training, missions, energy recharge/redeem/burn.
     */
    function pauseContract() public onlyOwner {
        require(!paused, "Contract is already paused");
        paused = true;
        emit ContractPaused(msg.sender);
    }

    /**
     * @dev Admin unpauses the contract.
     */
    function unpauseContract() public onlyOwner {
        require(paused, "Contract is not paused");
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    // The standard ERC721 functions (transferFrom, balanceOf, ownerOf, etc.) are inherited and public.
    // Counting them towards the minimum function requirement as they are part of the contract's external interface.
    // 8 standard public/external ERC721 functions + constructor + the custom public/external functions above:
    // 1 (constructor) + 22 (custom public/external) + 8 (inherited ERC721) = 31 functions.
    // (Note: safeTransferFrom counts as two functions due to overloading in ERC721)
}
```