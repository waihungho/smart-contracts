This smart contract introduces an **Evolving Autonomous Agent Network (EAAN)**, a novel concept where on-chain "agents" possess algorithmic DNA, allowing them to evolve, interact, learn, and procreate within a simulated ecosystem. Unlike typical NFTs or game assets, these agents have dynamic behavioral profiles encoded in their DNA, which can mutate and adapt based on interactions and environmental data.

The core idea is to create a living, evolving system entirely managed by the smart contract, where users can own, nurture, and observe the progression of their agents through distinct epochs. It blends concepts from genetic algorithms, decentralized autonomous organizations (DAO-lite for agents), and on-chain simulations.

---

### **Contract: `EvolvingAgentNetwork`**

#### **Outline & Function Summary:**

This contract manages a network of unique, evolving agents. Each agent has a `DNA` struct defining its behavioral characteristics, which can change over time through mutation and procreation. The network operates in epochs, with agents interacting, earning performance scores, and receiving rewards.

**I. Core Agent & DNA Management:**
*   **`DNA` Struct:** Defines an agent's behavioral genes (e.g., aggression, collaboration, adaptability, resource efficiency).
*   **`Agent` Struct:** Represents an agent with its ID, owner, DNA, generation, energy, status, and performance metrics.
*   **`AgentStatus` Enum:** Defines the possible states of an agent (e.g., Active, Hibernating, Deceased).

**II. Epoch & Time Management:**
*   `startEpoch()`: Initiates a new epoch, callable by the contract owner.
*   `endEpoch()`: Concludes the current epoch, triggering performance evaluations and rewards. Callable once the epoch duration has passed.
*   `advanceEpoch()`: Combines `endEpoch` and `startEpoch` logic to gracefully transition to the next epoch.

**III. Agent Creation & Ownership:**
*   `mintInitialAgent(uint256 initialAggression, ...)`: Creates a new, first-generation agent with specified initial DNA parameters. Requires a token payment.
*   `procreateAgent(uint256 parent1Id, uint256 parent2Id)`: Creates a new agent by combining and mutating the DNA of two existing parent agents. Requires energy and a fee.
*   `transferAgentOwnership(uint256 agentId, address newOwner)`: Allows an agent's owner to transfer its ownership.

**IV. Agent Evolution & DNA Mechanics:**
*   `mutateAgentDNA(uint256 agentId)`: Triggers a random, minor mutation on an agent's DNA. Requires agent energy.
*   `proposeDNAOverride(uint256 agentId, DNA newDNA)`: Allows an agent owner to propose a specific, significant change to an agent's DNA, subject to a higher cost.
*   `applyDNAOverride(uint256 agentId)`: Applies a pending DNA override after a cooldown period and payment.

**V. Agent Interaction & Performance:**
*   `simulateInteraction(uint256 agent1Id, uint256 agent2Id, uint256 resourceAmount)`: Simulates an interaction between two agents over a resource, updating their energy and performance based on their DNA.
*   `reportOracleData(bytes32 dataHash)`: Allows a designated oracle to submit external data that might influence agent adaptability or environmental factors.
*   `evaluateAgentPerformance()`: An internal/admin triggered function that aggregates performance scores for all active agents at the end of an epoch.
*   `allocateEpochRewards()`: Distributes `rewardToken` to top-performing agents based on their epoch performance.

**VI. Agent Energy & Resource Management:**
*   `stakeForAgentEnergy(uint256 agentId)`: Users can stake tokens to provide energy to an agent, fueling its activities.
*   `withdrawAgentStake(uint256 agentId)`: Allows an agent owner to withdraw staked tokens from their agent after a cooldown.
*   `transferAgentEnergy(uint256 fromAgentId, uint256 toAgentId, uint256 amount)`: Transfers energy between an owner's agents.

**VII. Agent Status & Lifecycle:**
*   `deactivateAgent(uint256 agentId)`: Puts an agent into `Hibernating` status, pausing its activity and reducing its energy consumption.
*   `reconstituteAgent(uint256 agentId)`: Activates a hibernating agent, requiring a minimum energy top-up.
*   `burnAgent(uint256 agentId)`: Permanently removes an agent from the network, potentially reclaiming a portion of its initial stake.

**VIII. Governance & Parameters:**
*   `setEpochDuration(uint256 duration)`: Sets the duration of each epoch.
*   `setOracleAddress(address _oracleAddress)`: Sets the address of the trusted oracle.
*   `setMutationFee(uint256 fee)`: Sets the cost for `mutateAgentDNA`.
*   `setProcreationFee(uint256 fee)`: Sets the cost for `procreateAgent`.
*   `setInteractionGasLimit(uint256 gasLimit)`: Sets a gas limit for `simulateInteraction` to prevent OOG errors for complex calculations.
*   `setInitialAgentMintCost(uint256 cost)`: Sets the token cost for minting a new initial agent.
*   `setRewardToken(address _rewardToken)`: Sets the ERC20 token used for epoch rewards.
*   `withdrawContractFunds(address tokenAddress)`: Allows the owner to withdraw collected fees from the contract.

**IX. View & Query Functions:**
*   `getAgentDetails(uint256 agentId)`: Returns all details of a specific agent.
*   `getAgentDNA(uint256 agentId)`: Returns the DNA genes of a specific agent.
*   `getAgentsByOwner(address ownerAddress)`: Returns an array of agent IDs owned by a specific address.
*   `getTopPerformingAgents(uint256 epoch)`: Returns a list of agents with the highest performance in a given epoch. (Simplified to return top X or just IDs for gas efficiency).
*   `getEpochInfo()`: Returns current epoch details (ID, start time, end time).
*   `getAgentEnergyBalance(uint256 agentId)`: Returns the current energy of an agent.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Note: For a real-world high-throughput system, complex on-chain simulations like
// `simulateInteraction` and global loops like `evaluateAgentPerformance` might require
// off-chain computation with ZK-proofs, batched transactions, or a more sophisticated
// Layer 2 scaling solution to manage gas costs and transaction limits effectively.
// This contract demonstrates the conceptual framework.

contract EvolvingAgentNetwork is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    // --- Enums ---
    enum AgentStatus {
        Active,
        Hibernating,
        Deceased // Burned or permanently removed
    }

    // --- Structs ---

    /// @dev Represents the algorithmic DNA of an agent, influencing its behavior.
    /// Values are typically 0-100 or 0-255 for gene intensity.
    struct DNA {
        uint256 aggressionGene;       // How aggressive in resource acquisition (0-100)
        uint256 collaborationGene;    // How likely to share/collaborate (0-100)
        uint256 adaptabilityGene;     // How quickly it adjusts strategy to new data (0-100)
        uint256 resourceEfficiencyGene; // How efficiently it uses energy (0-100)
        uint256 mutationResistanceGene; // Resistance to random DNA mutations (0-100)
        uint256 reproductionUrgeGene; // Likelihood to seek procreation (0-100)
        uint256 charismaGene;         // Influences other agents (simulated social interaction) (0-100)
        uint256 defenseGene;          // How well it defends its resources (0-100)
        uint256 intelligenceGene;     // How effective it is at processing oracle data (0-100)
        // Additional genes can be added, up to a full 256-bit hash equivalent for complexity
    }

    /// @dev Represents a unique agent in the network.
    struct Agent {
        uint256 id;
        address owner;
        DNA dna;
        uint256 generation;
        uint256 energy; // Resource consumed for actions, gained from interactions
        AgentStatus status;
        uint256 createdAt;
        uint256 lastInteractedAt;
        uint256 currentEpochPerformance; // Performance score for the current epoch
        uint256 totalPerformanceScore;   // Cumulative performance across all epochs
        uint256 interactionCount;        // Total interactions
        uint256 stakedFunds;             // Funds staked by the owner for this agent's energy
        uint256 dnaOverrideProposalBlock; // Block number when an override was proposed
        DNA proposedDNA;                 // Proposed DNA override
    }

    // --- State Variables ---

    uint256 private _nextTokenId; // Counter for unique agent IDs
    uint256 public currentEpoch;
    uint256 public epochStartTime;

    address public oracleAddress;
    address public rewardToken; // ERC20 token used for rewards

    uint256 public epochDuration; // Duration of an epoch in seconds
    uint256 public mutationFee;   // Cost for mutating DNA
    uint256 public procreationFee; // Cost for procreating new agents
    uint256 public initialAgentMintCost; // Cost for minting a new first-gen agent
    uint256 public dnaOverrideCooldownBlocks; // Blocks required before applying DNA override
    uint256 public agentBurnRefundPercentage; // % of initial mint cost refunded on burn (0-100)
    uint256 public minEnergyForReconstitution; // Minimum energy required to reactivate a hibernating agent

    uint256 public constant MAX_GENE_VALUE = 100; // Max value for any gene
    uint256 public constant MIN_GENE_VALUE = 0;   // Min value for any gene

    // --- Mappings ---

    mapping(uint256 => Agent) public agents;
    mapping(address => uint256[]) public ownerAgents; // Agent IDs owned by an address
    mapping(uint256 => uint256) public agentIndexInOwnerArray; // To efficiently remove from ownerAgents
    mapping(uint256 => uint256) public agentEpochPerformance[uint256]; // epochId => agentId => performance score
    mapping(uint256 => bool) public isAgentActive; // Quick check for active status

    // --- Events ---

    event AgentMinted(uint256 indexed agentId, address indexed owner, uint256 generation);
    event AgentProcreated(uint256 indexed agentId, address indexed owner, uint256 parent1, uint256 parent2, uint256 generation);
    event AgentDNAMutated(uint256 indexed agentId, DNA oldDNA, DNA newDNA);
    event DNAOverrideProposed(uint256 indexed agentId, address indexed proposer, DNA proposedDNA);
    event DNAOverrideApplied(uint256 indexed agentId, DNA oldDNA, DNA newDNA);
    event AgentEnergyStaked(uint256 indexed agentId, address indexed staker, uint256 amount);
    event AgentEnergyWithdrawn(uint256 indexed agentId, address indexed withdrawer, uint256 amount);
    event AgentEnergyTransferred(uint256 indexed fromAgentId, uint256 indexed toAgentId, uint256 amount);
    event AgentInteraction(uint256 indexed agent1Id, uint256 indexed agent2Id, uint256 outcomeFor1, uint256 outcomeFor2);
    event AgentDeactivated(uint256 indexed agentId);
    event AgentReconstituted(uint256 indexed agentId);
    event AgentBurned(uint256 indexed agentId, address indexed owner);
    event EpochStarted(uint256 indexed epochId, uint256 startTime);
    event EpochEnded(uint256 indexed epochId, uint256 endTime);
    event EpochRewardsDistributed(uint256 indexed epochId, uint256 agentId, uint256 amount);
    event OracleDataReported(bytes32 indexed dataHash);
    event OwnershipTransferred(uint256 indexed agentId, address indexed oldOwner, address indexed newOwner);

    // --- Modifiers ---

    modifier onlyAgentOwner(uint256 _agentId) {
        require(agents[_agentId].owner == _msgSender(), "EAN: Not agent owner");
        _;
    }

    modifier onlyActiveAgent(uint256 _agentId) {
        require(agents[_agentId].status == AgentStatus.Active, "EAN: Agent not active");
        _;
    }

    modifier onlyOracle() {
        require(_msgSender() == oracleAddress, "EAN: Only callable by the oracle");
        _;
    }

    modifier notInOverrideCooldown(uint256 _agentId) {
        require(agents[_agentId].dnaOverrideProposalBlock == 0 ||
                block.number >= agents[_agentId].dnaOverrideProposalBlock.add(dnaOverrideCooldownBlocks),
                "EAN: DNA override still in cooldown period");
        _;
    }

    // --- Constructor ---

    constructor(
        address _rewardToken,
        address _oracleAddress,
        uint256 _epochDuration,
        uint256 _mutationFee,
        uint256 _procreationFee,
        uint256 _initialAgentMintCost
    ) {
        rewardToken = _rewardToken;
        oracleAddress = _oracleAddress;
        epochDuration = _epochDuration;
        mutationFee = _mutationFee;
        procreationFee = _procreationFee;
        initialAgentMintCost = _initialAgentMintCost;
        dnaOverrideCooldownBlocks = 100; // Example: approx 25 minutes assuming 15s block time
        agentBurnRefundPercentage = 50; // 50% refund on burn
        minEnergyForReconstitution = 100; // Minimum energy to reactivate

        currentEpoch = 0; // Epoch 0 is the initial setup phase
        epochStartTime = block.timestamp; // Set for Epoch 0
    }

    // --- Admin & Governance Functions (Owner-only) ---

    /// @dev Sets the duration for each epoch.
    /// @param _duration The new epoch duration in seconds.
    function setEpochDuration(uint256 _duration) external onlyOwner {
        require(_duration > 0, "EAN: Epoch duration must be positive");
        epochDuration = _duration;
    }

    /// @dev Sets the address of the trusted oracle.
    /// @param _oracleAddress The new oracle contract address.
    function setOracleAddress(address _oracleAddress) external onlyOwner {
        require(_oracleAddress != address(0), "EAN: Oracle address cannot be zero");
        oracleAddress = _oracleAddress;
    }

    /// @dev Sets the fee required for an agent to mutate its DNA.
    /// @param _fee The new mutation fee.
    function setMutationFee(uint256 _fee) external onlyOwner {
        mutationFee = _fee;
    }

    /// @dev Sets the fee required for two agents to procreate.
    /// @param _fee The new procreation fee.
    function setProcreationFee(uint256 _fee) external onlyOwner {
        procreationFee = _fee;
    }

    /// @dev Sets the initial token cost for minting a new first-generation agent.
    /// @param _cost The new initial agent mint cost.
    function setInitialAgentMintCost(uint256 _cost) external onlyOwner {
        initialAgentMintCost = _cost;
    }

    /// @dev Sets the ERC20 token address used for epoch rewards.
    /// @param _rewardToken The address of the reward token.
    function setRewardToken(address _rewardToken) external onlyOwner {
        require(_rewardToken != address(0), "EAN: Reward token cannot be zero address");
        rewardToken = _rewardToken;
    }

    /// @dev Sets the number of blocks an agent's DNA override proposal must wait before it can be applied.
    /// @param _blocks The number of blocks for the cooldown period.
    function setDnaOverrideCooldownBlocks(uint256 _blocks) external onlyOwner {
        dnaOverrideCooldownBlocks = _blocks;
    }

    /// @dev Sets the percentage of the initial mint cost refunded when an agent is burned.
    /// @param _percentage The refund percentage (0-100).
    function setAgentBurnRefundPercentage(uint256 _percentage) external onlyOwner {
        require(_percentage <= 100, "EAN: Percentage cannot exceed 100");
        agentBurnRefundPercentage = _percentage;
    }

    /// @dev Sets the minimum energy an agent needs to be reconstituted from hibernation.
    /// @param _energy The minimum energy amount.
    function setMinEnergyForReconstitution(uint256 _energy) external onlyOwner {
        minEnergyForReconstitution = _energy;
    }

    /// @dev Allows the owner to withdraw collected fees from the contract.
    /// @param _tokenAddress The address of the token to withdraw (e.g., Ether, or an ERC20 token like the rewardToken).
    function withdrawContractFunds(address _tokenAddress) external onlyOwner nonReentrant {
        if (_tokenAddress == address(0)) { // Withdraw native currency
            uint256 balance = address(this).balance;
            require(balance > 0, "EAN: No native currency to withdraw");
            payable(owner()).transfer(balance);
        } else { // Withdraw ERC20 token
            IERC20 token = IERC20(_tokenAddress);
            uint256 balance = token.balanceOf(address(this));
            require(balance > 0, "EAN: No ERC20 balance to withdraw");
            token.transfer(owner(), balance);
        }
    }

    // --- Epoch Management ---

    /// @dev Starts a new epoch. Can only be called by owner or when previous epoch is over.
    function startEpoch() public onlyOwner {
        require(block.timestamp >= epochStartTime.add(epochDuration), "EAN: Current epoch has not ended yet");
        
        currentEpoch = currentEpoch.add(1);
        epochStartTime = block.timestamp;
        
        // Reset epoch-specific agent performance data
        // NOTE: Iterating over all agents can be gas-intensive. In a real system,
        // this might be handled by an off-chain process or a more gas-optimized approach.
        // For this example, we'll assume a manageable number of active agents.
        for (uint256 i = 1; i <= _nextTokenId; i++) {
            if (agents[i].status == AgentStatus.Active) {
                agents[i].currentEpochPerformance = 0;
            }
        }
        
        emit EpochStarted(currentEpoch, epochStartTime);
    }

    /// @dev Ends the current epoch. Triggers performance evaluation and reward allocation.
    /// Can only be called when the epoch duration has passed.
    function endEpoch() public onlyOwner nonReentrant {
        require(block.timestamp >= epochStartTime.add(epochDuration), "EAN: Epoch has not ended yet");
        
        // Evaluate agent performance and allocate rewards for the *just ended* epoch
        // For simplicity, we directly call these, but in a large system, they might be separate calls
        _evaluateAgentPerformance(); // Updates totalPerformanceScore based on currentEpochPerformance
        _allocateEpochRewards(); // Distributes rewards to top agents

        emit EpochEnded(currentEpoch, block.timestamp);
    }

    /// @dev Advances the network to the next epoch. Combines endEpoch and startEpoch logic.
    function advanceEpoch() public onlyOwner {
        endEpoch(); // Ends the current epoch, evaluates, and distributes rewards
        startEpoch(); // Starts the next epoch
    }

    // --- Agent Creation & Ownership ---

    /// @dev Mints a new first-generation agent with initial DNA parameters.
    /// @param _initialAggression The initial aggression gene value (0-100).
    /// @param _initialCollaboration The initial collaboration gene value (0-100).
    /// @param _initialAdaptability The initial adaptability gene value (0-100).
    /// @param _initialResourceEfficiency The initial resource efficiency gene value (0-100).
    /// @param _initialMutationResistance The initial mutation resistance gene value (0-100).
    /// @param _initialReproductionUrge The initial reproduction urge gene value (0-100).
    /// @param _initialCharisma The initial charisma gene value (0-100).
    /// @param _initialDefense The initial defense gene value (0-100).
    /// @param _initialIntelligence The initial intelligence gene value (0-100).
    function mintInitialAgent(
        uint256 _initialAggression,
        uint256 _initialCollaboration,
        uint256 _initialAdaptability,
        uint256 _initialResourceEfficiency,
        uint256 _initialMutationResistance,
        uint256 _initialReproductionUrge,
        uint256 _initialCharisma,
        uint256 _initialDefense,
        uint256 _initialIntelligence
    ) external nonReentrant {
        require(IERC20(rewardToken).transferFrom(_msgSender(), address(this), initialAgentMintCost), "EAN: Initial agent mint payment failed");

        _nextTokenId = _nextTokenId.add(1);
        uint256 newAgentId = _nextTokenId;

        DNA memory newDNA = DNA({
            aggressionGene: _clampGene(_initialAggression),
            collaborationGene: _clampGene(_initialCollaboration),
            adaptabilityGene: _clampGene(_initialAdaptability),
            resourceEfficiencyGene: _clampGene(_initialResourceEfficiency),
            mutationResistanceGene: _clampGene(_initialMutationResistance),
            reproductionUrgeGene: _clampGene(_initialReproductionUrge),
            charismaGene: _clampGene(_initialCharisma),
            defenseGene: _clampGene(_initialDefense),
            intelligenceGene: _clampGene(_initialIntelligence)
        });

        agents[newAgentId] = Agent({
            id: newAgentId,
            owner: _msgSender(),
            dna: newDNA,
            generation: 1,
            energy: 1000, // Initial energy for new agents
            status: AgentStatus.Active,
            createdAt: block.timestamp,
            lastInteractedAt: block.timestamp,
            currentEpochPerformance: 0,
            totalPerformanceScore: 0,
            interactionCount: 0,
            stakedFunds: initialAgentMintCost, // Initial mint cost is considered staked
            dnaOverrideProposalBlock: 0,
            proposedDNA: DNA(0,0,0,0,0,0,0,0,0) // Placeholder
        });

        _addAgentToOwner(_msgSender(), newAgentId);
        isAgentActive[newAgentId] = true;

        emit AgentMinted(newAgentId, _msgSender(), 1);
    }

    /// @dev Creates a new agent by combining DNA from two parent agents.
    /// Requires parents to be owned by the caller and have sufficient energy.
    /// @param _parent1Id ID of the first parent agent.
    /// @param _parent2Id ID of the second parent agent.
    function procreateAgent(uint256 _parent1Id, uint256 _parent2Id) external onlyAgentOwner(_parent1Id) onlyActiveAgent(_parent1Id) nonReentrant {
        require(_parent1Id != _parent2Id, "EAN: Parents cannot be the same agent");
        require(agents[_parent2Id].owner == _msgSender(), "EAN: Caller must own both parent agents");
        require(agents[_parent2Id].status == AgentStatus.Active, "EAN: Parent 2 not active");
        require(agents[_parent1Id].energy >= procreationFee.mul(2), "EAN: Parent 1 has insufficient energy");
        require(agents[_parent2Id].energy >= procreationFee.mul(2), "EAN: Parent 2 has insufficient energy");
        
        // Fee payment for procreation
        // Can be a separate token or a portion of parent energy
        agents[_parent1Id].energy = agents[_parent1Id].energy.sub(procreationFee);
        agents[_parent2Id].energy = agents[_parent2Id].energy.sub(procreationFee);

        _nextTokenId = _nextTokenId.add(1);
        uint256 childAgentId = _nextTokenId;

        // Simple DNA mixing and mutation (e.g., average and slight random change)
        DNA memory parent1DNA = agents[_parent1Id].dna;
        DNA memory parent2DNA = agents[_parent2Id].dna;
        DNA memory childDNA;

        childDNA.aggressionGene = _mixAndMutateGene(parent1DNA.aggressionGene, parent2DNA.aggressionGene);
        childDNA.collaborationGene = _mixAndMutateGene(parent1DNA.collaborationGene, parent2DNA.collaborationGene);
        childDNA.adaptabilityGene = _mixAndMutateGene(parent1DNA.adaptabilityGene, parent2DNA.adaptabilityGene);
        childDNA.resourceEfficiencyGene = _mixAndMutateGene(parent1DNA.resourceEfficiencyGene, parent2DNA.resourceEfficiencyGene);
        childDNA.mutationResistanceGene = _mixAndMutateGene(parent1DNA.mutationResistanceGene, parent2DNA.mutationResistanceGene);
        childDNA.reproductionUrgeGene = _mixAndMutateGene(parent1DNA.reproductionUrgeGene, parent2DNA.reproductionUrgeGene);
        childDNA.charismaGene = _mixAndMutateGene(parent1DNA.charismaGene, parent2DNA.charismaGene);
        childDNA.defenseGene = _mixAndMutateGene(parent1DNA.defenseGene, parent2DNA.defenseGene);
        childDNA.intelligenceGene = _mixAndMutateGene(parent1DNA.intelligenceGene, parent2DNA.intelligenceGene);

        agents[childAgentId] = Agent({
            id: childAgentId,
            owner: _msgSender(),
            dna: childDNA,
            generation: _max(agents[_parent1Id].generation, agents[_parent2Id].generation).add(1),
            energy: 500, // Child gets some initial energy
            status: AgentStatus.Active,
            createdAt: block.timestamp,
            lastInteractedAt: block.timestamp,
            currentEpochPerformance: 0,
            totalPerformanceScore: 0,
            interactionCount: 0,
            stakedFunds: 0, // Children start with no staked funds initially
            dnaOverrideProposalBlock: 0,
            proposedDNA: DNA(0,0,0,0,0,0,0,0,0)
        });

        _addAgentToOwner(_msgSender(), childAgentId);
        isAgentActive[childAgentId] = true;

        emit AgentProcreated(childAgentId, _msgSender(), _parent1Id, _parent2Id, agents[childAgentId].generation);
    }
    
    /// @dev Transfers ownership of an agent to a new address.
    /// @param _agentId The ID of the agent to transfer.
    /// @param _newOwner The address of the new owner.
    function transferAgentOwnership(uint256 _agentId, address _newOwner) external onlyAgentOwner(_agentId) {
        require(_newOwner != address(0), "EAN: New owner cannot be the zero address");
        require(_newOwner != agents[_agentId].owner, "EAN: New owner is already the current owner");

        address oldOwner = agents[_agentId].owner;
        agents[_agentId].owner = _newOwner;

        _removeAgentFromOwner(oldOwner, _agentId);
        _addAgentToOwner(_newOwner, _agentId);

        emit OwnershipTransferred(_agentId, oldOwner, _newOwner);
    }


    // --- Agent Evolution & DNA Mechanics ---

    /// @dev Triggers a minor, random mutation on an agent's DNA.
    /// Requires agent energy as a cost.
    /// @param _agentId The ID of the agent to mutate.
    function mutateAgentDNA(uint256 _agentId) external onlyAgentOwner(_agentId) onlyActiveAgent(_agentId) nonReentrant {
        require(agents[_agentId].energy >= mutationFee, "EAN: Insufficient agent energy for mutation");
        
        agents[_agentId].energy = agents[_agentId].energy.sub(mutationFee);

        DNA memory oldDNA = agents[_agentId].dna;
        DNA memory newDNA = oldDNA;

        // Apply random small mutation to one or more genes
        // Mutation resistance gene reduces the severity of mutation
        uint256 resistanceFactor = (MAX_GENE_VALUE.sub(oldDNA.mutationResistanceGene)).add(1); // 1 to 101
        uint256 mutationAmount = (uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, _agentId, "mutate")) % (MAX_GENE_VALUE.div(10)))); // Max +/- 10% of MAX_GENE_VALUE
        mutationAmount = mutationAmount.div(resistanceFactor).mul(10); // Scale by resistance, inverse relationship

        uint256 geneToMutate = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, _agentId, "gene")) % 9); // Selects one of 9 genes

        if (uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, _agentId, "sign"))) % 2 == 0) {
            // Positive mutation
            if (geneToMutate == 0) newDNA.aggressionGene = _clampGene(newDNA.aggressionGene.add(mutationAmount));
            else if (geneToMutate == 1) newDNA.collaborationGene = _clampGene(newDNA.collaborationGene.add(mutationAmount));
            else if (geneToMutate == 2) newDNA.adaptabilityGene = _clampGene(newDNA.adaptabilityGene.add(mutationAmount));
            else if (geneToMutate == 3) newDNA.resourceEfficiencyGene = _clampGene(newDNA.resourceEfficiencyGene.add(mutationAmount));
            else if (geneToMutate == 4) newDNA.mutationResistanceGene = _clampGene(newDNA.mutationResistanceGene.add(mutationAmount));
            else if (geneToMutate == 5) newDNA.reproductionUrgeGene = _clampGene(newDNA.reproductionUrgeGene.add(mutationAmount));
            else if (geneToMutate == 6) newDNA.charismaGene = _clampGene(newDNA.charismaGene.add(mutationAmount));
            else if (geneToMutate == 7) newDNA.defenseGene = _clampGene(newDNA.defenseGene.add(mutationAmount));
            else if (geneToMutate == 8) newDNA.intelligenceGene = _clampGene(newDNA.intelligenceGene.add(mutationAmount));
        } else {
            // Negative mutation
            if (geneToMutate == 0) newDNA.aggressionGene = _clampGene(newDNA.aggressionGene.sub(mutationAmount));
            else if (geneToMutate == 1) newDNA.collaborationGene = _clampGene(newDNA.collaborationGene.sub(mutationAmount));
            else if (geneToMutate == 2) newDNA.adaptabilityGene = _clampGene(newDNA.adaptabilityGene.sub(mutationAmount));
            else if (geneToMutate == 3) newDNA.resourceEfficiencyGene = _clampGene(newDNA.resourceEfficiencyGene.sub(mutationAmount));
            else if (geneToMutate == 4) newDNA.mutationResistanceGene = _clampGene(newDNA.mutationResistanceGene.sub(mutationAmount));
            else if (geneToMutate == 5) newDNA.reproductionUrgeGene = _clampGene(newDNA.reproductionUrgeGene.sub(mutationAmount));
            else if (geneToMutate == 6) newDNA.charismaGene = _clampGene(newDNA.charismaGene.sub(mutationAmount));
            else if (geneToMutate == 7) newDNA.defenseGene = _clampGene(newDNA.defenseGene.sub(mutationAmount));
            else if (geneToMutate == 8) newDNA.intelligenceGene = _clampGene(newDNA.intelligenceGene.sub(mutationAmount));
        }

        agents[_agentId].dna = newDNA;
        emit AgentDNAMutated(_agentId, oldDNA, newDNA);
    }

    /// @dev Allows an agent owner to propose a specific, significant change to an agent's DNA.
    /// This change is subject to a cooldown period and requires a separate `applyDNAOverride` call.
    /// @param _agentId The ID of the agent whose DNA is being overridden.
    /// @param _newDNA The proposed new DNA for the agent.
    function proposeDNAOverride(uint256 _agentId, DNA memory _newDNA) external onlyAgentOwner(_agentId) onlyActiveAgent(_agentId) notInOverrideCooldown(_agentId) {
        // Clamp all genes in the proposed DNA to ensure validity
        _newDNA.aggressionGene = _clampGene(_newDNA.aggressionGene);
        _newDNA.collaborationGene = _clampGene(_newDNA.collaborationGene);
        _newDNA.adaptabilityGene = _clampGene(_newDNA.adaptabilityGene);
        _newDNA.resourceEfficiencyGene = _clampGene(_newDNA.resourceEfficiencyGene);
        _newDNA.mutationResistanceGene = _clampGene(_newDNA.mutationResistanceGene);
        _newDNA.reproductionUrgeGene = _clampGene(_newDNA.reproductionUrgeGene);
        _newDNA.charismaGene = _clampGene(_newDNA.charismaGene);
        _newDNA.defenseGene = _clampGene(_newDNA.defenseGene);
        _newDNA.intelligenceGene = _clampGene(_newDNA.intelligenceGene);

        agents[_agentId].proposedDNA = _newDNA;
        agents[_agentId].dnaOverrideProposalBlock = block.number;

        emit DNAOverrideProposed(_agentId, _msgSender(), _newDNA);
    }

    /// @dev Applies a pending DNA override after its cooldown period has passed.
    /// Requires an additional fee.
    /// @param _agentId The ID of the agent to apply the override to.
    function applyDNAOverride(uint256 _agentId) external onlyAgentOwner(_agentId) onlyActiveAgent(_agentId) nonReentrant {
        require(agents[_agentId].dnaOverrideProposalBlock != 0, "EAN: No DNA override proposal active");
        require(block.number >= agents[_agentId].dnaOverrideProposalBlock.add(dnaOverrideCooldownBlocks), "EAN: DNA override still in cooldown");
        require(agents[_agentId].energy >= mutationFee.mul(5), "EAN: Insufficient agent energy for DNA override application"); // Higher cost

        agents[_agentId].energy = agents[_agentId].energy.sub(mutationFee.mul(5));
        
        DNA memory oldDNA = agents[_agentId].dna;
        agents[_agentId].dna = agents[_agentId].proposedDNA;
        
        // Reset proposal
        agents[_agentId].dnaOverrideProposalBlock = 0;
        agents[_agentId].proposedDNA = DNA(0,0,0,0,0,0,0,0,0);

        emit DNAOverrideApplied(_agentId, oldDNA, agents[_agentId].dna);
    }

    // --- Agent Interaction & Performance ---

    /// @dev Simulates an interaction between two agents over a given resource amount.
    /// The outcome (energy gain/loss, performance update) depends on their DNA.
    /// This is a simplified model for demonstration.
    /// @param _agent1Id The ID of the first participating agent.
    /// @param _agent2Id The ID of the second participating agent.
    /// @param _resourceAmount The amount of resource (e.g., energy, reward) at stake in the interaction.
    function simulateInteraction(uint256 _agent1Id, uint256 _agent2Id, uint256 _resourceAmount) external nonReentrant {
        require(isAgentActive[_agent1Id], "EAN: Agent 1 not active");
        require(isAgentActive[_agent2Id], "EAN: Agent 2 not active");
        require(_agent1Id != _agent2Id, "EAN: Agents cannot interact with themselves");
        require(_resourceAmount > 0, "EAN: Resource amount must be positive");

        Agent storage agent1 = agents[_agent1Id];
        Agent storage agent2 = agents[_agent2Id];

        // Cost for interaction
        uint256 interactionCost = 10; // Base energy cost per interaction
        require(agent1.energy >= interactionCost, "EAN: Agent 1 has insufficient energy for interaction");
        require(agent2.energy >= interactionCost, "EAN: Agent 2 has insufficient energy for interaction");
        agent1.energy = agent1.energy.sub(interactionCost);
        agent2.energy = agent2.energy.sub(interactionCost);

        // --- Simplified Interaction Logic ---
        // Outcome depends on a blend of genes. For example, aggression vs defense,
        // or collaboration for a shared win. A random factor is usually involved.
        
        // Pseudo-random factor for outcome variability
        uint256 randomSeed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, agent1.id, agent2.id)));
        
        int256 outcome1 = 0;
        int256 outcome2 = 0;
        
        // Example logic: Aggression vs. Defense
        // If agent1 is more aggressive and agent2 is less defensive, agent1 gains more.
        // If they are collaborative, both gain.
        
        uint256 interactionHash = uint256(keccak256(abi.encodePacked(block.timestamp, agent1.id, agent2.id, randomSeed))) % 100;

        if (interactionHash < 30) { // Aggressive encounter
            if (agent1.dna.aggressionGene > agent2.dna.defenseGene) {
                outcome1 = int256(_resourceAmount.mul(70).div(100)); // Agent 1 gets 70%
                outcome2 = int256(_resourceAmount.mul(30).div(100)); // Agent 2 gets 30%
            } else if (agent2.dna.aggressionGene > agent1.dna.defenseGene) {
                outcome2 = int256(_resourceAmount.mul(70).div(100));
                outcome1 = int256(_resourceAmount.mul(30).div(100));
            } else { // Balanced defense/aggression
                outcome1 = int256(_resourceAmount.div(2));
                outcome2 = int256(_resourceAmount.div(2));
            }
        } else if (interactionHash < 70) { // Collaborative encounter
            if (agent1.dna.collaborationGene > 50 && agent2.dna.collaborationGene > 50) {
                // High collaboration, both gain
                outcome1 = int256(_resourceAmount.mul(60).div(100)); // Both get more than half
                outcome2 = int256(_resourceAmount.mul(60).div(100)); // Simulating a positive sum game with external resource
                agent1.energy = agent1.energy.add(_resourceAmount.mul(10).div(100)); // Extra energy from collaboration
                agent2.energy = agent2.energy.add(_resourceAmount.mul(10).div(100));
            } else {
                outcome1 = int256(_resourceAmount.div(2));
                outcome2 = int256(_resourceAmount.div(2));
            }
        } else { // Random outcome
            outcome1 = int256(randomSeed % _resourceAmount);
            outcome2 = int256(_resourceAmount.sub(uint256(outcome1)));
        }

        // Update energy and performance
        agent1.energy = agent1.energy.add(uint256(outcome1));
        agent2.energy = agent2.energy.add(uint256(outcome2));

        agent1.currentEpochPerformance = agent1.currentEpochPerformance.add(uint256(outcome1)); // Performance based on gained resources
        agent2.currentEpochPerformance = agent2.currentEpochPerformance.add(uint256(outcome2));

        agent1.interactionCount = agent1.interactionCount.add(1);
        agent2.interactionCount = agent2.interactionCount.add(1);
        agent1.lastInteractedAt = block.timestamp;
        agent2.lastInteractedAt = block.timestamp;

        emit AgentInteraction(_agent1Id, _agent2Id, uint256(outcome1), uint256(outcome2));
    }

    /// @dev Allows the designated oracle to report external data.
    /// This data can influence agent adaptability or environmental conditions.
    /// @param _dataHash A hash representing the external data reported by the oracle.
    function reportOracleData(bytes32 _dataHash) external onlyOracle {
        // This function just logs the data. A more advanced implementation
        // would process this data, potentially affecting all agents' performance
        // or triggering environmental changes based on `adaptabilityGene`.
        emit OracleDataReported(_dataHash);
    }

    /// @dev Internal function to evaluate agent performance at the end of an epoch.
    /// Updates total performance and prepares for reward distribution.
    function _evaluateAgentPerformance() internal {
        // This is highly gas-intensive for many agents.
        // A production system would require pagination, off-chain computation, or L2.
        for (uint256 i = 1; i <= _nextTokenId; i++) {
            if (agents[i].status == AgentStatus.Active) {
                // Store performance for this epoch
                agentEpochPerformance[currentEpoch][i] = agents[i].currentEpochPerformance;
                // Add to total performance
                agents[i].totalPerformanceScore = agents[i].totalPerformanceScore.add(agents[i].currentEpochPerformance);
            }
        }
    }

    /// @dev Allocates rewards (rewardToken) to top-performing agents for the current epoch.
    /// The number of top agents and reward structure can be configured.
    function _allocateEpochRewards() internal {
        // Collect all active agents' performance for the current epoch
        struct AgentPerformance {
            uint256 agentId;
            uint256 performance;
        }
        AgentPerformance[] memory epochPerformances = new AgentPerformance[](_nextTokenId);
        uint256 activeAgentCount = 0;

        for (uint256 i = 1; i <= _nextTokenId; i++) {
            if (agents[i].status == AgentStatus.Active) {
                epochPerformances[activeAgentCount] = AgentPerformance(i, agents[i].currentEpochPerformance);
                activeAgentCount++;
            }
        }

        // Simple sorting (bubble sort for small N, or external sorting for large N)
        // For demonstration, we assume a small enough N or a simpler reward model.
        // A more robust solution might pass sorted data from an off-chain oracle.
        for (uint256 i = 0; i < activeAgentCount; i++) {
            for (uint256 j = i + 1; j < activeAgentCount; j++) {
                if (epochPerformances[i].performance < epochPerformances[j].performance) {
                    AgentPerformance memory temp = epochPerformances[i];
                    epochPerformances[i] = epochPerformances[j];
                    epochPerformances[j] = temp;
                }
            }
        }

        // Distribute rewards to top 5 (example)
        uint256 rewardPool = IERC20(rewardToken).balanceOf(address(this));
        uint256 rewardPerAgent = rewardPool.div(5); // Example: distribute equally among top 5
        
        for (uint256 i = 0; i < _min(activeAgentCount, 5); i++) {
            uint256 agentId = epochPerformances[i].agentId;
            if (agentEpochPerformance[currentEpoch][agentId] > 0) { // Only reward if they actually performed
                IERC20(rewardToken).transfer(agents[agentId].owner, rewardPerAgent);
                emit EpochRewardsDistributed(currentEpoch, agentId, rewardPerAgent);
            }
        }
    }

    // --- Agent Energy & Resource Management ---

    /// @dev Allows a user to stake reward tokens to provide energy to an agent.
    /// Staked funds are recorded and can be withdrawn later.
    /// @param _agentId The ID of the agent to stake for.
    function stakeForAgentEnergy(uint256 _agentId) external payable onlyActiveAgent(_agentId) nonReentrant {
        require(msg.value > 0, "EAN: Must stake a positive amount"); // Assuming native currency for staking

        agents[_agentId].stakedFunds = agents[_agentId].stakedFunds.add(msg.value);
        // Convert staked value to energy, e.g., 1 ETH = 10000 energy
        agents[_agentId].energy = agents[_agentId].energy.add(msg.value.mul(100)); // Example conversion rate

        emit AgentEnergyStaked(_agentId, _msgSender(), msg.value);
    }

    /// @dev Allows an agent owner to withdraw their staked funds from an agent.
    /// Subject to a cooldown or unlocking period (not implemented, placeholder).
    /// @param _agentId The ID of the agent to withdraw from.
    function withdrawAgentStake(uint256 _agentId) external onlyAgentOwner(_agentId) nonReentrant {
        require(agents[_agentId].stakedFunds > 0, "EAN: No staked funds to withdraw");

        uint256 amountToWithdraw = agents[_agentId].stakedFunds;
        agents[_agentId].stakedFunds = 0; // Withdraw all staked funds
        // Reduce energy accordingly, e.g., 10000 energy = 1 ETH
        agents[_agentId].energy = agents[_agentId].energy.sub(amountToWithdraw.mul(100)); // Reverse conversion

        payable(_msgSender()).transfer(amountToWithdraw);

        emit AgentEnergyWithdrawn(_agentId, _msgSender(), amountToWithdraw);
    }

    /// @dev Allows an agent owner to transfer energy between their own agents.
    /// @param _fromAgentId The ID of the agent to transfer energy from.
    /// @param _toAgentId The ID of the agent to transfer energy to.
    /// @param _amount The amount of energy to transfer.
    function transferAgentEnergy(uint256 _fromAgentId, uint256 _toAgentId, uint256 _amount) external onlyAgentOwner(_fromAgentId) {
        require(_fromAgentId != _toAgentId, "EAN: Cannot transfer energy to the same agent");
        require(agents[_toAgentId].owner == _msgSender(), "EAN: Caller must own the target agent");
        require(agents[_fromAgentId].energy >= _amount, "EAN: Insufficient energy in source agent");
        
        agents[_fromAgentId].energy = agents[_fromAgentId].energy.sub(_amount);
        agents[_toAgentId].energy = agents[_toAgentId].energy.add(_amount);

        emit AgentEnergyTransferred(_fromAgentId, _toAgentId, _amount);
    }

    // --- Agent Status & Lifecycle ---

    /// @dev Deactivates an agent, setting its status to Hibernating.
    /// Hibernating agents do not participate in interactions or evaluations but consume less energy.
    /// @param _agentId The ID of the agent to deactivate.
    function deactivateAgent(uint256 _agentId) external onlyAgentOwner(_agentId) {
        require(agents[_agentId].status == AgentStatus.Active, "EAN: Agent is not active");
        
        agents[_agentId].status = AgentStatus.Hibernating;
        isAgentActive[_agentId] = false;
        
        // Optional: Reduce energy significantly or apply maintenance cost
        agents[_agentId].energy = agents[_agentId].energy.div(2); // Example: Halve energy on hibernation
        
        emit AgentDeactivated(_agentId);
    }

    /// @dev Reconstitutes a hibernating agent, setting its status back to Active.
    /// Requires a minimum energy top-up.
    /// @param _agentId The ID of the agent to reconstitute.
    function reconstituteAgent(uint256 _agentId) external onlyAgentOwner(_agentId) nonReentrant {
        require(agents[_agentId].status == AgentStatus.Hibernating, "EAN: Agent is not hibernating");
        require(agents[_agentId].energy >= minEnergyForReconstitution, "EAN: Insufficient energy for reconstitution");
        
        agents[_agentId].status = AgentStatus.Active;
        isAgentActive[_agentId] = true;
        
        emit AgentReconstituted(_agentId);
    }

    /// @dev Permanently removes an agent from the network.
    /// A portion of the initial mint cost (if any) is refunded.
    /// @param _agentId The ID of the agent to burn.
    function burnAgent(uint256 _agentId) external onlyAgentOwner(_agentId) nonReentrant {
        require(agents[_agentId].status != AgentStatus.Deceased, "EAN: Agent is already deceased");

        address ownerToRefund = agents[_agentId].owner;
        uint256 refundAmount = agents[_agentId].stakedFunds.mul(agentBurnRefundPercentage).div(100);

        // Update agent status and clear data
        delete agents[_agentId];
        _removeAgentFromOwner(ownerToRefund, _agentId);
        isAgentActive[_agentId] = false; // Ensure it's marked inactive if not already

        // Refund any remaining staked funds
        if (refundAmount > 0) {
            payable(ownerToRefund).transfer(refundAmount);
        }

        emit AgentBurned(_agentId, ownerToRefund);
    }

    // --- View & Query Functions ---

    /// @dev Returns all detailed information about a specific agent.
    /// @param _agentId The ID of the agent.
    /// @return Agent struct containing all details.
    function getAgentDetails(uint256 _agentId) external view returns (Agent memory) {
        return agents[_agentId];
    }

    /// @dev Returns the DNA genes of a specific agent.
    /// @param _agentId The ID of the agent.
    /// @return DNA struct containing the agent's genes.
    function getAgentDNA(uint256 _agentId) external view returns (DNA memory) {
        return agents[_agentId].dna;
    }

    /// @dev Returns an array of agent IDs owned by a specific address.
    /// @param _ownerAddress The address of the owner.
    /// @return An array of agent IDs.
    function getAgentsByOwner(address _ownerAddress) external view returns (uint256[] memory) {
        return ownerAgents[_ownerAddress];
    }

    /// @dev Returns a list of agents with the highest performance in a given epoch.
    /// This is a simplified implementation; for a large network, off-chain sorting
    /// or a more complex on-chain leaderboard structure would be required.
    /// @param _epoch The epoch ID to query performance for.
    /// @param _topN The number of top agents to return.
    /// @return An array of agent IDs.
    function getTopPerformingAgents(uint256 _epoch, uint256 _topN) external view returns (uint256[] memory) {
        require(_topN > 0, "EAN: Top N must be greater than zero");
        uint256[] memory topAgentIds = new uint256[](_topN);
        uint256 currentBestPerformance = 0;
        uint256 foundCount = 0;

        // This is a naive way to find top N and will be gas-intensive for large N or agent count.
        // A more efficient method would involve maintaining a sorted list or using an external oracle.
        for (uint256 i = 1; i <= _nextTokenId; i++) {
            if (agentEpochPerformance[_epoch][i] > 0) {
                // Insert into sorted topAgentIds
                for (uint256 j = 0; j < _topN; j++) {
                    if (agentEpochPerformance[_epoch][i] > agentEpochPerformance[_epoch][topAgentIds[j]]) {
                        // Shift elements to make space
                        for (uint224 k = uint224(_topN - 1); k > j; k--) {
                            topAgentIds[k] = topAgentIds[k - 1];
                        }
                        topAgentIds[j] = i;
                        if (foundCount < _topN) foundCount++;
                        break;
                    }
                }
            }
        }
        
        // Resize array to actual found count if less than _topN
        uint256[] memory result = new uint256[](foundCount);
        for(uint256 i = 0; i < foundCount; i++) {
            result[i] = topAgentIds[i];
        }
        return result;
    }

    /// @dev Returns current epoch information.
    /// @return _currentEpoch Current epoch ID.
    /// @return _epochStartTime Timestamp when the current epoch started.
    /// @return _epochEndTime Timestamp when the current epoch is expected to end.
    function getEpochInfo() external view returns (uint256 _currentEpoch, uint256 _epochStartTime, uint256 _epochEndTime) {
        return (currentEpoch, epochStartTime, epochStartTime.add(epochDuration));
    }

    /// @dev Returns the current energy balance of a specific agent.
    /// @param _agentId The ID of the agent.
    /// @return The current energy amount.
    function getAgentEnergyBalance(uint256 _agentId) external view returns (uint256) {
        return agents[_agentId].energy;
    }

    // --- Internal/Private Helper Functions ---

    /// @dev Clamps a gene value between MIN_GENE_VALUE and MAX_GENE_VALUE.
    /// @param _value The gene value to clamp.
    /// @return The clamped gene value.
    function _clampGene(uint256 _value) internal pure returns (uint256) {
        return _min(_max(_value, MIN_GENE_VALUE), MAX_GENE_VALUE);
    }

    /// @dev Simple mixing and mutation logic for child DNA.
    /// Averages parents' genes with a small random deviation.
    /// @param _gene1 Parent 1 gene value.
    /// @param _gene2 Parent 2 gene value.
    /// @return The mixed and mutated child gene value.
    function _mixAndMutateGene(uint256 _gene1, uint256 _gene2) internal view returns (uint256) {
        uint256 avg = (_gene1.add(_gene2)).div(2);
        
        // Introduce small random mutation (e.g., +/- 5% of MAX_GENE_VALUE)
        uint256 mutationRange = MAX_GENE_VALUE.div(20); // 5%
        uint256 mutation = uint256(keccak256(abi.encodePacked(block.timestamp, _msgSender(), _gene1, _gene2))) % mutationRange;
        
        if (uint256(keccak256(abi.encodePacked(block.timestamp, _msgSender(), _gene1, _gene2, "sign"))) % 2 == 0) {
            return _clampGene(avg.add(mutation));
        } else {
            return _clampGene(avg.sub(mutation));
        }
    }

    /// @dev Helper to get the maximum of two uint256 values.
    function _max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /// @dev Helper to get the minimum of two uint256 values.
    function _min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a <= b ? a : b;
    }

    /// @dev Adds an agent ID to the owner's array of agents.
    /// @param _owner The address of the owner.
    /// @param _agentId The ID of the agent to add.
    function _addAgentToOwner(address _owner, uint256 _agentId) internal {
        ownerAgents[_owner].push(_agentId);
        agentIndexInOwnerArray[_agentId] = ownerAgents[_owner].length - 1;
    }

    /// @dev Removes an agent ID from the owner's array of agents.
    /// Uses a swap-and-pop method for O(1) removal.
    /// @param _owner The address of the owner.
    /// @param _agentId The ID of the agent to remove.
    function _removeAgentFromOwner(address _owner, uint256 _agentId) internal {
        uint256 index = agentIndexInOwnerArray[_agentId];
        uint256 lastIndex = ownerAgents[_owner].length - 1;
        
        if (index != lastIndex) {
            uint256 lastAgentId = ownerAgents[_owner][lastIndex];
            ownerAgents[_owner][index] = lastAgentId;
            agentIndexInOwnerArray[lastAgentId] = index;
        }
        ownerAgents[_owner].pop();
        delete agentIndexInOwnerArray[_agentId]; // Clear the index for the removed agent
    }
}
```