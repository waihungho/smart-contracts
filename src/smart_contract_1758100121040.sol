This smart contract, `GenesisAgentsProtocol`, introduces a decentralized ecosystem for creating, nurturing, and evolving AI-augmented "Digital Genesis Agents" (DGAs) as Non-Fungible Tokens (NFTs). Owners can mint these agents, stake resources (ETH) to power them, initiate training sessions, and assign them to various "tasks."

The core innovation lies in the dynamic nature of these agents. Their attributes (intelligence, adaptability, energy, affinity) are not static but evolve based on owner interactions, on-chain events, and most notably, off-chain AI model outputs verified by a trusted oracle. These AI outputs can manifest as new behavioral "directives" or trigger significant "evolutionary" phases for the agents. The contract also features unique concepts like agent delegation, owner reputation, and simulated agent-to-agent interactions, all built on a foundation of secure and auditable blockchain principles.

---

# GenesisAgentsProtocol

**Outline and Function Summary**

This contract, `GenesisAgentsProtocol`, introduces a novel ecosystem for AI-augmented, dynamically evolving "Digital Genesis Agents" (DGAs) as NFTs. Owners can mint, train, stake resources for, and assign tasks to their agents. Agents possess dynamic attributes influenced by off-chain AI models (via signed oracle updates) and on-chain interactions. The protocol emphasizes emergent behavior, reputation, and a gamified experience.

**I. Core Agent Management & Minting**
1.  **`mintGenesisAgent(string memory _agentName)`**: Allows users to mint a new Genesis Agent NFT, paying a fee. The agent receives initial attributes and a name.
2.  **`delegateAgentControl(uint256 _agentId, address _delegate)`**: Permits an agent owner to delegate operational control (e.g., initiating tasks, training) to another address. The owner still retains full ownership rights.
3.  **`revokeAgentControl(uint256 _agentId)`**: Revokes any previously delegated control for a specific agent.
4.  **`getAgent(uint256 _agentId)`**: A view function to retrieve all detailed attributes of a specified agent.
5.  **`getAgentsByOwner(address _owner)`**: A view function to list all agent IDs owned by a given address.

**II. Agent Evolution & Intelligence**
6.  **`initiateTrainingSession(uint256 _agentId, uint256 _durationBlocks)`**: Starts a training period for an agent, consuming energy and staking a minor amount. This process is designed to boost the agent's 'affinityScore' and 'intelligenceFactor' over time.
7.  **`completeTrainingSession(uint256 _agentId)`**: Concludes an active training session, applying statistical enhancements to the agent based on the training duration and effectiveness.
8.  **`updateAgentDirective(uint256 _agentId, bytes32 _directiveHash, uint256 _oracleTimestamp, bytes memory _signature)`**: An advanced function where a trusted oracle, after verifying off-chain AI model outputs, submits a signed hash representing a new behavioral directive for the agent. This dynamically influences the agent's future actions and potential.
9.  **`evolveAgent(uint256 _agentId, bytes32 _evolutionProofHash)`**: Triggers a major evolutionary step for an agent, provided it meets specific on-chain and potentially off-chain (verified by `_evolutionProofHash`) criteria. This can significantly alter its attributes and appearance.
10. **`recalibrateAgent(uint256 _agentId, uint256 _newAdaptabilityFactor)`**: Allows the owner to attempt to adjust their agent's 'adaptabilityFactor' (its capacity to incorporate new directives). This is a costly and potentially risky operation, with success depending on various conditions.
11. **`queryAgentStatus(uint256 _agentId)`**: A view function to get the current operational status of an agent, including any ongoing activity details (e.g., remaining training blocks).

**III. Resource Management & Staking**
12. **`stakeForAgent(uint256 _agentId, uint256 _amount)`**: Owners can stake ETH to provide "energy" for their agent's operations and potentially increase its influence or reward potential.
13. **`unstakeFromAgent(uint256 _agentId, uint256 _amount)`**: Allows owners to withdraw previously staked ETH from their agent, potentially subject to cooldowns or penalties if the agent is actively engaged.
14. **`claimAgentRewards(uint256 _agentId)`**: Enables owners to claim accumulated rewards that their agent has earned through tasks or collective achievements.
15. **`distributeProtocolRewards(address[] memory _agentOwners, uint256[] memory _amounts)`**: A governance- or admin-controlled function to distribute rewards from the protocol's treasury to multiple agent owners, typically for collective achievements or ecosystem incentives.

**IV. Task System & Interaction**
16. **`assignAgentToTask(uint256 _agentId, bytes32 _taskIdentifierHash, uint256 _energyCost)`**: The owner assigns their agent to an external "task" (e.g., a delegated computation or data gathering). This action consumes agent energy. The `_taskIdentifierHash` refers to off-chain task details.
17. **`completeAgentTask(uint256 _agentId, bytes32 _taskIdentifierHash, bytes32 _completionProofHash, uint256 _rewardAmount)`**: Callable by a designated "Task Master" or verified oracle. It validates task completion (e.g., by verifying `_completionProofHash` against off-chain results), awards rewards to the agent, and potentially updates its attributes.
18. **`initiateAgentInteraction(uint256 _agentId1, uint256 _agentId2)`**: Simulates an interaction between two agents (e.g., collaboration, competition). This interaction can dynamically influence their 'affinityScore', 'intelligenceFactor', or other attributes based on internal logic or oracle input.

**V. Protocol Governance & Administration**
19. **`pauseProtocol()`**: Enables the contract owner or governance to temporarily halt critical functions during emergencies or upgrades.
20. **`unpauseProtocol()`**: Resumes protocol operations after a pause.
21. **`updateOracleAddress(address _newOracle)`**: Allows the contract owner/governance to update the address of the trusted oracle responsible for submitting agent directives and task completion proofs.
22. **`setMintingFee(uint256 _newFee)`**: Permits the contract owner/governance to adjust the fee required to mint a new Genesis Agent.
23. **`withdrawProtocolFees(address _to, uint256 _amount)`**: Allows the contract owner/governance to withdraw collected protocol fees to a specified address.

**Standard ERC721 Functions (not counted towards the 20 unique creative functions):**
*   `ownerOf(uint256 tokenId)`: Returns the owner of the NFT.
*   `approve(address to, uint256 tokenId)`: Grants approval to a third party to transfer a specific NFT.
*   `getApproved(uint256 tokenId)`: Returns the approved address for a specific NFT.
*   `setApprovalForAll(address operator, bool approved)`: Grants/revokes approval for an operator to manage all of the sender's NFTs.
*   `isApprovedForAll(address owner, address operator)`: Checks if an operator is approved for all of an owner's NFTs.
*   `transferFrom(address from, address to, uint256 tokenId)`: Transfers an NFT from one address to another (requires approval or being the owner).
*   `safeTransferFrom(address from, address to, uint256 tokenId)`: Same as `transferFrom`, but with safety checks.
*   `supportsInterface(bytes4 interfaceId)`: Used for ERC-165 introspection.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol"; // For verifying oracle signatures
import "@openzeppelin/contracts/utils/Strings.sol"; // For tokenURI

contract GenesisAgentsProtocol is ERC721, Ownable, Pausable {
    using ECDSA for bytes32;

    // --- Events ---
    event AgentMinted(uint256 indexed agentId, address indexed owner, string agentName, uint256 genesisTimestamp);
    event AgentControlDelegated(uint256 indexed agentId, address indexed owner, address indexed delegate);
    event AgentControlRevoked(uint256 indexed agentId, address indexed owner, address indexed previousDelegate);
    event TrainingInitiated(uint256 indexed agentId, address indexed owner, uint256 durationBlocks);
    event TrainingCompleted(uint256 indexed agentId, address indexed owner, uint256 intelligenceBoost, uint256 affinityBoost);
    event AgentDirectiveUpdated(uint256 indexed agentId, bytes32 newDirectiveHash, uint256 oracleTimestamp);
    event AgentEvolved(uint256 indexed agentId, address indexed owner, bytes32 evolutionProofHash);
    event AgentRecalibrated(uint256 indexed agentId, address indexed owner, uint256 oldAdaptability, uint256 newAdaptability, bool success);
    event AgentStaked(uint256 indexed agentId, address indexed owner, uint256 amount);
    event AgentUnstaked(uint256 indexed agentId, address indexed owner, uint256 amount);
    event RewardsClaimed(uint256 indexed agentId, address indexed owner, uint256 amount);
    event ProtocolRewardsDistributed(address indexed distributor, uint256 totalAmount);
    event AgentAssignedToTask(uint256 indexed agentId, address indexed owner, bytes32 taskIdentifierHash, uint256 energyCost);
    event AgentTaskCompleted(uint256 indexed agentId, bytes32 taskIdentifierHash, bytes32 completionProofHash, uint256 rewardAmount);
    event AgentInteraction(uint256 indexed agentId1, uint256 indexed agentId2, string interactionType);
    event OracleAddressUpdated(address indexed oldOracle, address indexed newOracle);
    event MintingFeeUpdated(uint256 oldFee, uint256 newFee);
    event FeesWithdrawn(address indexed to, uint256 amount);

    // --- Enums ---
    enum AgentStatus {
        Idle,
        Training,
        PerformingTask,
        Evolving
    }

    // --- Structs ---
    struct Agent {
        uint256 agentId;
        address ownerAddress; // Storing owner redundantly with ERC721 for quick struct access
        string name; // Human-readable name
        uint256 genesisTimestamp;
        uint256 lastEvolutionTimestamp;
        uint256 energyLevel; // Consumes for actions
        uint256 affinityScore; // Owner bond, influences training success
        uint256 intelligenceFactor; // Core AI metric
        uint256 adaptabilityFactor; // How well it uses new data/directives
        bytes32 currentDirectiveHash; // Hash of AI-generated directive (off-chain)
        AgentStatus currentStatus;
        uint256 statusEndTime; // Timestamp or block for training/task completion
        uint256 stakedAmount; // ETH staked by owner to power agent
        uint256 pendingRewards;
        address delegatedController; // Address allowed to control agent actions
        bool isGenesisAgent; // Initial agents vs. spawned/evolved types
    }

    // --- State Variables ---
    uint256 private _agentCounter; // To assign unique agent IDs
    mapping(uint256 => Agent) public agents; // Agent ID => Agent struct
    mapping(address => uint256[]) public ownerAgentIds; // Owner address => Array of agent IDs
    mapping(address => uint256) public ownerReputation; // Owner address => Reputation score

    address public oracleAddress; // Address of the trusted oracle
    uint256 public mintingFee; // Fee to mint a new genesis agent
    address public feeCollectorAddress; // Address where fees are sent

    // --- Constants ---
    uint256 public constant BASE_ENERGY_COST_PER_ACTION = 100;
    uint256 public constant MIN_STAKE_FOR_TRAINING = 0.001 ether;
    uint256 public constant TRAINING_ENERGY_COST_PER_BLOCK = 10;
    uint256 public constant RECALIBRATION_COST = 0.01 ether;

    // --- Constructor ---
    /// @dev Initializes the contract, setting the name and symbol for the ERC721,
    ///      and establishing the initial oracle and fee collector addresses.
    /// @param _initialOracle The address of the initial trusted oracle.
    /// @param _initialFeeCollector The address to send collected fees to.
    constructor(address _initialOracle, address _initialFeeCollector)
        ERC721("GenesisAgent", "GENESIS")
        Ownable(msg.sender) // Set deployer as initial owner
    {
        require(_initialOracle != address(0), "GAP: Invalid initial oracle address");
        require(_initialFeeCollector != address(0), "GAP: Invalid fee collector address");
        oracleAddress = _initialOracle;
        feeCollectorAddress = _initialFeeCollector;
        mintingFee = 0.05 ether; // Example initial minting fee
    }

    // --- Modifiers ---
    /// @dev Checks if the caller is the agent's owner or its delegated controller.
    modifier onlyAgentOwnerOrDelegate(uint256 _agentId) {
        require(_exists(_agentId), "GAP: Agent does not exist");
        require(
            _msgSender() == ERC721.ownerOf(_agentId) || _msgSender() == agents[_agentId].delegatedController,
            "GAP: Only agent owner or delegated controller can perform this action"
        );
        _;
    }

    /// @dev Checks if the caller is the agent's owner.
    modifier onlyAgentOwner(uint256 _agentId) {
        require(_exists(_agentId), "GAP: Agent does not exist");
        require(_msgSender() == ERC721.ownerOf(_agentId), "GAP: Only agent owner can perform this action");
        _;
    }

    /// @dev Checks if the caller is the trusted oracle.
    modifier onlyOracle() {
        require(_msgSender() == oracleAddress, "GAP: Only trusted oracle can call this function");
        _;
    }

    // --- I. Core Agent Management & Minting ---
    /// @dev Allows users to mint a new Genesis Agent NFT, paying a fee. The agent receives initial attributes and a name.
    /// @param _agentName The human-readable name for the new agent.
    /// @return The ID of the newly minted agent.
    function mintGenesisAgent(string memory _agentName) public payable whenNotPaused returns (uint256) {
        require(msg.value >= mintingFee, "GAP: Insufficient minting fee");

        _agentCounter++;
        uint256 newAgentId = _agentCounter;

        _safeMint(msg.sender, newAgentId);

        agents[newAgentId] = Agent({
            agentId: newAgentId,
            ownerAddress: msg.sender,
            name: _agentName,
            genesisTimestamp: block.timestamp,
            lastEvolutionTimestamp: block.timestamp,
            energyLevel: 1000, // Initial energy
            affinityScore: 50, // Initial affinity
            intelligenceFactor: 100, // Initial intelligence
            adaptabilityFactor: 50, // Initial adaptability
            currentDirectiveHash: bytes32(0), // No initial directive
            currentStatus: AgentStatus.Idle,
            statusEndTime: 0,
            stakedAmount: 0,
            pendingRewards: 0,
            delegatedController: address(0),
            isGenesisAgent: true
        });

        ownerAgentIds[msg.sender].push(newAgentId);
        (bool success, ) = feeCollectorAddress.call{value: msg.value}("");
        require(success, "GAP: Fee transfer failed");

        emit AgentMinted(newAgentId, msg.sender, _agentName, block.timestamp);
        return newAgentId;
    }

    /// @dev Permits an agent owner to delegate operational control (e.g., initiating tasks, training) to another address.
    ///      The owner still retains full ownership rights.
    /// @param _agentId The ID of the agent.
    /// @param _delegate The address to delegate control to.
    function delegateAgentControl(uint256 _agentId, address _delegate) public onlyAgentOwner(_agentId) whenNotPaused {
        require(_delegate != address(0), "GAP: Cannot delegate to zero address");
        agents[_agentId].delegatedController = _delegate;
        emit AgentControlDelegated(_agentId, _msgSender(), _delegate);
    }

    /// @dev Revokes any previously delegated control for a specific agent.
    /// @param _agentId The ID of the agent.
    function revokeAgentControl(uint256 _agentId) public onlyAgentOwner(_agentId) whenNotPaused {
        address previousDelegate = agents[_agentId].delegatedController;
        require(previousDelegate != address(0), "GAP: No delegate to revoke");
        agents[_agentId].delegatedController = address(0);
        emit AgentControlRevoked(_agentId, _msgSender(), previousDelegate);
    }

    /// @dev A view function to retrieve all detailed attributes of a specified agent.
    /// @param _agentId The ID of the agent.
    /// @return Agent struct containing all details.
    function getAgent(uint256 _agentId) public view returns (Agent memory) {
        require(_exists(_agentId), "GAP: Agent does not exist");
        return agents[_agentId];
    }

    /// @dev A view function to list all agent IDs owned by a given address.
    /// @param _owner The address of the owner.
    /// @return An array of agent IDs.
    function getAgentsByOwner(address _owner) public view returns (uint256[] memory) {
        return ownerAgentIds[_owner];
    }

    // --- II. Agent Evolution & Intelligence ---

    /// @dev Starts a training period for an agent, consuming energy and staking a minor amount.
    ///      This process is designed to boost the agent's 'affinityScore' and 'intelligenceFactor' over time.
    /// @param _agentId The ID of the agent.
    /// @param _durationBlocks The duration of the training session in blocks.
    function initiateTrainingSession(uint256 _agentId, uint256 _durationBlocks) public onlyAgentOwnerOrDelegate(_agentId) whenNotPaused {
        Agent storage agent = agents[_agentId];
        require(agent.currentStatus == AgentStatus.Idle, "GAP: Agent is not idle");
        require(agent.energyLevel >= BASE_ENERGY_COST_PER_ACTION, "GAP: Insufficient energy to start training");
        require(agent.stakedAmount >= MIN_STAKE_FOR_TRAINING, "GAP: Insufficient staked ETH for training");
        require(_durationBlocks > 0, "GAP: Training duration must be positive");

        uint256 totalEnergyCost = TRAINING_ENERGY_COST_PER_BLOCK * _durationBlocks;
        require(agent.energyLevel >= totalEnergyCost, "GAP: Not enough energy for this training duration");

        agent.energyLevel -= totalEnergyCost;
        agent.currentStatus = AgentStatus.Training;
        agent.statusEndTime = block.number + _durationBlocks; // Using block.number for block-based duration

        emit TrainingInitiated(_agentId, agent.ownerAddress, _durationBlocks);
    }

    /// @dev Concludes an active training session, applying statistical enhancements to the agent
    ///      based on the training duration and effectiveness.
    /// @param _agentId The ID of the agent.
    function completeTrainingSession(uint256 _agentId) public onlyAgentOwnerOrDelegate(_agentId) whenNotPaused {
        Agent storage agent = agents[_agentId];
        require(agent.currentStatus == AgentStatus.Training, "GAP: Agent is not currently training");
        require(block.number >= agent.statusEndTime, "GAP: Training session not yet complete");

        uint256 trainingBlocks = agent.statusEndTime - (block.number - agent.statusEndTime); // Approximate blocks trained
        uint256 intelligenceBoost = (trainingBlocks * agent.affinityScore) / 1000; // Example logic
        uint256 affinityBoost = trainingBlocks / 10; // Example logic

        agent.intelligenceFactor += intelligenceBoost;
        agent.affinityScore += affinityBoost;
        agent.currentStatus = AgentStatus.Idle;
        agent.statusEndTime = 0;

        emit TrainingCompleted(_agentId, agent.ownerAddress, intelligenceBoost, affinityBoost);
    }

    /// @dev An advanced function where a trusted oracle, after verifying off-chain AI model outputs,
    ///      submits a signed hash representing a new behavioral directive for the agent.
    ///      This dynamically influences the agent's future actions and potential.
    /// @param _agentId The ID of the agent.
    /// @param _directiveHash The SHA256 hash of the off-chain AI-generated directive.
    /// @param _oracleTimestamp The timestamp from the oracle when the directive was generated.
    /// @param _signature The ECDSA signature from the oracle.
    function updateAgentDirective(uint256 _agentId, bytes32 _directiveHash, uint256 _oracleTimestamp, bytes memory _signature) public onlyOracle whenNotPaused {
        Agent storage agent = agents[_agentId];
        require(_directiveHash != bytes32(0), "GAP: Directive hash cannot be zero");
        require(_oracleTimestamp > agent.genesisTimestamp, "GAP: Oracle timestamp must be after agent genesis");

        // Construct the message hash that was signed by the oracle
        bytes32 messageHash = keccak256(abi.encodePacked(_agentId, _directiveHash, _oracleTimestamp, block.chainid));
        address signer = messageHash.toEthSignedMessageHash().recover(_signature);
        require(signer == oracleAddress, "GAP: Invalid oracle signature");

        agent.currentDirectiveHash = _directiveHash;
        // Optionally, update adaptability based on some logic, e.g., if the agent was "ready" for a new directive
        agent.adaptabilityFactor = (agent.adaptabilityFactor * 105) / 100; // Small adaptability boost

        emit AgentDirectiveUpdated(_agentId, _directiveHash, _oracleTimestamp);
    }

    /// @dev Triggers a major evolutionary step for an agent, provided it meets specific on-chain
    ///      and potentially off-chain (verified by `_evolutionProofHash`) criteria.
    ///      This can significantly alter its attributes and appearance.
    /// @param _agentId The ID of the agent.
    /// @param _evolutionProofHash A hash representing off-chain proof that criteria for evolution were met.
    function evolveAgent(uint256 _agentId, bytes32 _evolutionProofHash) public onlyAgentOwnerOrDelegate(_agentId) whenNotPaused {
        Agent storage agent = agents[_agentId];
        require(agent.currentStatus == AgentStatus.Idle, "GAP: Agent must be idle to evolve");
        require(agent.intelligenceFactor >= 500, "GAP: Agent intelligence too low for evolution"); // Example criteria
        require(agent.affinityScore >= 200, "GAP: Agent affinity too low for evolution"); // Example criteria
        require(_evolutionProofHash != bytes32(0), "GAP: Evolution proof hash required");

        // In a real scenario, _evolutionProofHash might be verified by a ZK-proof verifier contract
        // For this example, we'll just check it's not zero and assume off-chain verification is handled.
        // It's a placeholder for more advanced verification.

        agent.intelligenceFactor = (agent.intelligenceFactor * 120) / 100; // Major boost
        agent.adaptabilityFactor = (agent.adaptabilityFactor * 110) / 100; // Major boost
        agent.energyLevel += 500; // Bonus energy
        agent.lastEvolutionTimestamp = block.timestamp;
        agent.currentStatus = AgentStatus.Evolving; // Agent is temporarily 'evolving'
        agent.statusEndTime = block.timestamp + 1 hours; // Evolution takes 1 hour (example)

        // Note: Metadata URI would dynamically change based on these stats, handled by an off-chain renderer.

        emit AgentEvolved(_agentId, agent.ownerAddress, _evolutionProofHash);
    }

    /// @dev Allows the owner to attempt to adjust their agent's 'adaptabilityFactor' (its capacity to incorporate new directives).
    ///      This is a costly and potentially risky operation, with success depending on various conditions.
    /// @param _agentId The ID of the agent.
    /// @param _newAdaptabilityFactor The desired new adaptability factor.
    function recalibrateAgent(uint256 _agentId, uint256 _newAdaptabilityFactor) public payable onlyAgentOwner(_agentId) whenNotPaused {
        Agent storage agent = agents[_agentId];
        require(msg.value >= RECALIBRATION_COST, "GAP: Insufficient ETH for recalibration");
        require(agent.currentStatus == AgentStatus.Idle, "GAP: Agent must be idle for recalibration");
        require(_newAdaptabilityFactor <= 200, "GAP: Adaptability factor cannot exceed 200 (for balance)");
        require(_newAdaptabilityFactor >= 10, "GAP: Adaptability factor cannot be less than 10");

        uint256 oldAdaptability = agent.adaptabilityFactor;
        bool success = false;

        // Complex recalibration logic: depends on intelligence, affinity, current adaptability, etc.
        if (agent.intelligenceFactor >= 300 && agent.affinityScore >= 150 && _newAdaptabilityFactor > oldAdaptability) {
            // High intelligence/affinity allows for better upward recalibration
            agent.adaptabilityFactor = _newAdaptabilityFactor;
            success = true;
        } else if (_newAdaptabilityFactor < oldAdaptability) {
            // Lowering adaptability is generally easier
            agent.adaptabilityFactor = _newAdaptabilityFactor;
            success = true;
        } else if (agent.intelligenceFactor < 300 && _newAdaptabilityFactor > oldAdaptability) {
            // Attempting to raise with low intelligence might only partially succeed or fail
            agent.adaptabilityFactor = (oldAdaptability + _newAdaptabilityFactor) / 2; // Partial success
            success = true; // Still considered a success, just not full
        } else {
            // No change or failed attempt
            success = false;
        }
        
        (bool feeSuccess, ) = feeCollectorAddress.call{value: msg.value}("");
        require(feeSuccess, "GAP: Recalibration fee transfer failed");

        emit AgentRecalibrated(_agentId, _msgSender(), oldAdaptability, agent.adaptabilityFactor, success);
    }

    /// @dev A view function to get the current operational status of an agent,
    ///      including any ongoing activity details (e.g., remaining training blocks).
    /// @param _agentId The ID of the agent.
    /// @return currentStatus The current status enum.
    /// @return statusEndTime The block number or timestamp when the current status ends.
    function queryAgentStatus(uint256 _agentId) public view returns (AgentStatus currentStatus, uint256 statusEndTime) {
        Agent storage agent = agents[_agentId];
        return (agent.currentStatus, agent.statusEndTime);
    }

    // --- III. Resource Management & Staking ---

    /// @dev Owners can stake ETH to provide "energy" for their agent's operations and potentially
    ///      increase its influence or reward potential.
    /// @param _agentId The ID of the agent.
    /// @param _amount The amount of ETH to stake.
    function stakeForAgent(uint256 _agentId, uint256 _amount) public payable onlyAgentOwner(_agentId) whenNotPaused {
        require(msg.value == _amount, "GAP: Sent ETH must match staking amount");
        Agent storage agent = agents[_agentId];
        agent.stakedAmount += _amount;
        agent.energyLevel += (_amount / 1 ether) * 500; // 500 energy per ETH staked (example conversion)
        emit AgentStaked(_agentId, _msgSender(), _amount);
    }

    /// @dev Allows owners to withdraw previously staked ETH from their agent, potentially subject
    ///      to cooldowns or penalties if the agent is actively engaged.
    /// @param _agentId The ID of the agent.
    /// @param _amount The amount of ETH to unstake.
    function unstakeFromAgent(uint256 _agentId, uint256 _amount) public onlyAgentOwner(_agentId) whenNotPaused {
        Agent storage agent = agents[_agentId];
        require(agent.stakedAmount >= _amount, "GAP: Insufficient staked amount");
        // Add cooldown logic here if agent is performing a task or training for more advanced systems
        require(agent.currentStatus == AgentStatus.Idle, "GAP: Cannot unstake while agent is active");

        agent.stakedAmount -= _amount;
        // Optionally reduce energy, or have a separate energy decay mechanism
        (bool success, ) = _msgSender().call{value: _amount}("");
        require(success, "GAP: ETH unstake transfer failed");
        emit AgentUnstaked(_agentId, _msgSender(), _amount);
    }

    /// @dev Enables owners to claim accumulated rewards that their agent has earned through tasks
    ///      or collective achievements.
    /// @param _agentId The ID of the agent.
    function claimAgentRewards(uint256 _agentId) public onlyAgentOwner(_agentId) whenNotPaused {
        Agent storage agent = agents[_agentId];
        uint256 rewards = agent.pendingRewards;
        require(rewards > 0, "GAP: No pending rewards to claim");

        agent.pendingRewards = 0;
        (bool success, ) = _msgSender().call{value: rewards}("");
        require(success, "GAP: Reward transfer failed");
        emit RewardsClaimed(_agentId, _msgSender(), rewards);
    }

    /// @dev Governance- or admin-controlled function to distribute rewards from the protocol's treasury
    ///      to multiple agent owners, typically for collective achievements or ecosystem incentives.
    /// @param _agentOwners An array of owner addresses to receive rewards.
    /// @param _amounts An array of amounts corresponding to each owner.
    function distributeProtocolRewards(address[] memory _agentOwners, uint252[] memory _amounts) public onlyOwner whenNotPaused {
        require(_agentOwners.length == _amounts.length, "GAP: Mismatched array lengths");
        uint256 totalDistributed = 0;
        for (uint256 i = 0; i < _agentOwners.length; i++) {
            require(_amounts[i] > 0, "GAP: Reward amount must be positive");
            // For simplicity, we assume each owner has at least one agent and reward goes to the first one.
            // In a more complex system, this might be distributed to ALL agents of an owner or a specific one.
            require(ownerAgentIds[_agentOwners[i]].length > 0, "GAP: Owner has no agents to receive rewards");
            Agent storage agent = agents[ownerAgentIds[_agentOwners[i]][0]];
            agent.pendingRewards += _amounts[i];
            totalDistributed += _amounts[i];
        }
        emit ProtocolRewardsDistributed(_msgSender(), totalDistributed);
    }


    // --- IV. Task System & Interaction ---

    /// @dev The owner assigns their agent to an external "task" (e.g., a delegated computation or data gathering).
    ///      This action consumes agent energy. The `_taskIdentifierHash` refers to off-chain task details.
    /// @param _agentId The ID of the agent.
    /// @param _taskIdentifierHash A hash referring to off-chain task details.
    /// @param _energyCost The energy required for the task.
    function assignAgentToTask(uint256 _agentId, bytes32 _taskIdentifierHash, uint256 _energyCost) public onlyAgentOwnerOrDelegate(_agentId) whenNotPaused {
        Agent storage agent = agents[_agentId];
        require(agent.currentStatus == AgentStatus.Idle, "GAP: Agent is not idle");
        require(agent.energyLevel >= _energyCost, "GAP: Insufficient energy for this task");
        require(_taskIdentifierHash != bytes32(0), "GAP: Task identifier hash cannot be zero");

        agent.energyLevel -= _energyCost;
        agent.currentStatus = AgentStatus.PerformingTask;
        agent.statusEndTime = block.timestamp + 30 minutes; // Example task duration
        // Store taskIdentifierHash somewhere if needed for verification later, or rely on _completionProofHash

        emit AgentAssignedToTask(_agentId, agent.ownerAddress, _taskIdentifierHash, _energyCost);
    }

    /// @dev Callable by a designated "Task Master" or verified oracle. It validates task completion
    ///      (e.g., by verifying `_completionProofHash` against off-chain results), awards rewards to the agent,
    ///      and potentially updates its attributes.
    /// @param _agentId The ID of the agent.
    /// @param _taskIdentifierHash The hash identifying the completed task.
    /// @param _completionProofHash A hash proving the task was completed off-chain.
    /// @param _rewardAmount The reward for completing the task.
    function completeAgentTask(uint256 _agentId, bytes32 _taskIdentifierHash, bytes32 _completionProofHash, uint256 _rewardAmount) public onlyOracle whenNotPaused {
        Agent storage agent = agents[_agentId];
        require(agent.currentStatus == AgentStatus.PerformingTask, "GAP: Agent is not performing a task");
        // In a real system, _taskIdentifierHash might be checked against a stored active task
        require(_completionProofHash != bytes32(0), "GAP: Completion proof hash required");
        require(block.timestamp >= agent.statusEndTime, "GAP: Task not yet completed by duration");

        // The _completionProofHash would ideally be verified against expected results off-chain,
        // or against a specific ZK-proof verifier contract if applicable.
        // For this contract, we simply check it's non-zero and trust the oracle.

        agent.pendingRewards += _rewardAmount;
        agent.intelligenceFactor += 10; // Small intelligence boost for task completion
        ownerReputation[agent.ownerAddress] += 5; // Boost owner reputation
        agent.currentStatus = AgentStatus.Idle;
        agent.statusEndTime = 0;

        emit AgentTaskCompleted(_agentId, _taskIdentifierHash, _completionProofHash, _rewardAmount);
    }

    /// @dev Simulates an interaction between two agents (e.g., collaboration, competition).
    ///      This interaction can dynamically influence their 'affinityScore', 'intelligenceFactor',
    ///      or other attributes based on internal logic or oracle input.
    /// @param _agentId1 The ID of the first agent.
    /// @param _agentId2 The ID of the second agent.
    function initiateAgentInteraction(uint256 _agentId1, uint256 _agentId2) public whenNotPaused {
        require(_agentId1 != _agentId2, "GAP: Agents cannot interact with themselves");
        Agent storage agent1 = agents[_agentId1];
        Agent storage agent2 = agents[_agentId2];

        require(agent1.currentStatus == AgentStatus.Idle && agent2.currentStatus == AgentStatus.Idle, "GAP: Both agents must be idle for interaction");
        require(agent1.energyLevel >= BASE_ENERGY_COST_PER_ACTION && agent2.energyLevel >= BASE_ENERGY_COST_PER_ACTION, "GAP: Both agents need energy for interaction");

        agent1.energyLevel -= BASE_ENERGY_COST_PER_ACTION;
        agent2.energyLevel -= BASE_ENERGY_COST_PER_ACTION;

        // Example interaction logic: based on their intelligence and adaptability
        if (agent1.intelligenceFactor > agent2.intelligenceFactor && agent1.adaptabilityFactor > agent2.adaptabilityFactor) {
            agent1.affinityScore += 5;
            agent2.affinityScore = agent2.affinityScore > 2 ? agent2.affinityScore - 2 : 0; // Prevent negative
            emit AgentInteraction(_agentId1, _agentId2, "Dominance-Collaboration");
        } else if (agent2.intelligenceFactor > agent1.intelligenceFactor && agent2.adaptabilityFactor > agent1.adaptabilityFactor) {
            agent2.affinityScore += 5;
            agent1.affinityScore = agent1.affinityScore > 2 ? agent1.affinityScore - 2 : 0; // Prevent negative
            emit AgentInteraction(_agentId2, _agentId1, "Dominance-Collaboration");
        } else {
            // Mutual learning/cooperation
            agent1.intelligenceFactor += 3;
            agent2.intelligenceFactor += 3;
            agent1.affinityScore += 1;
            agent2.affinityScore += 1;
            emit AgentInteraction(_agentId1, _agentId2, "Mutual-Learning");
        }
    }

    // --- V. Protocol Governance & Administration ---

    /// @dev Enables the contract owner or governance to temporarily halt critical functions
    ///      during emergencies or upgrades.
    function pauseProtocol() public onlyOwner {
        _pause();
    }

    /// @dev Resumes protocol operations after a pause.
    function unpauseProtocol() public onlyOwner {
        _unpause();
    }

    /// @dev Allows the contract owner/governance to update the address of the trusted oracle
    ///      responsible for submitting agent directives and task completion proofs.
    /// @param _newOracle The new address for the oracle.
    function updateOracleAddress(address _newOracle) public onlyOwner {
        require(_newOracle != address(0), "GAP: New oracle address cannot be zero");
        emit OracleAddressUpdated(oracleAddress, _newOracle);
        oracleAddress = _newOracle;
    }

    /// @dev Permits the contract owner/governance to adjust the fee required to mint a new Genesis Agent.
    /// @param _newFee The new minting fee in wei.
    function setMintingFee(uint256 _newFee) public onlyOwner {
        require(_newFee > 0, "GAP: Minting fee must be positive");
        emit MintingFeeUpdated(mintingFee, _newFee);
        mintingFee = _newFee;
    }

    /// @dev Allows the contract owner/governance to withdraw collected protocol fees to a specified address.
    /// @param _to The address to send the fees to.
    /// @param _amount The amount of fees to withdraw.
    function withdrawProtocolFees(address _to, uint256 _amount) public onlyOwner {
        require(_to != address(0), "GAP: Target address cannot be zero");
        require(address(this).balance >= _amount, "GAP: Insufficient contract balance");
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "GAP: Fee withdrawal failed");
        emit FeesWithdrawn(_to, _amount);
    }

    // --- ERC721 Overrides ---
    /// @dev Returns the base URI for a given token, which dynamically reflects its on-chain state.
    ///      In a real dApp, this would point to an API endpoint that queries the contract's state
    ///      and generates a JSON metadata file with image, description, and dynamic attributes.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        Agent storage agent = agents[tokenId];
        // Example: https://my-dapp.com/api/agent/{tokenId}?status={status_enum_value}
        return string(abi.encodePacked("https://genesisagents.xyz/api/agent/", Strings.toString(tokenId), "?status=", Strings.toString(uint256(agent.currentStatus))));
    }

    // Prevents direct ETH transfers to the contract, except through designated functions (minting, staking).
    receive() external payable {
        revert("GAP: Direct ETH deposits not allowed. Use stakeForAgent or mintGenesisAgent.");
    }
}
```