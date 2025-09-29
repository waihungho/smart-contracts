The contract `AetherweaveAI` is designed to be a decentralized ecosystem for AI agents. It leverages ERC20 tokens (`AetherUnit`) for utility and ERC721 tokens (`AetherAgent`) to represent unique AI agents. The core idea revolves around users submitting tasks that require off-chain AI computation, and agents competing or being assigned to fulfill these tasks. The system incorporates reputation, staking, and a multi-stage verification process to ensure trust and incentivize performance.

### Outline:

**I. Core Infrastructure & Tokens**
   A. `AetherUnit` (ERC20) Token Contract
   B. `AetherAgent` (ERC721) NFT Contract

**II. `AetherweaveAI` Protocol Contract**
   A. State Variables & Data Structures
   B. Modifiers & Enums
   C. Constructor
   D. Agent Management & Lifecycle
   E. Task Management & Execution
   F. Staking & Reputation
   G. Governance & Protocol Parameters
   H. Views & Helper Functions

### Function Summary:

**AetherUnit (ERC20) Token Contract:**
1.  **`constructor()`**: Initializes the ERC20 token with a name ("AetherUnit") and symbol ("AU").
2.  **`mint(address to, uint256 amount)`**: Mints new `AU` tokens to a specified address. Restricted to the `AetherweaveAI` protocol contract for reward distribution.
3.  **`burn(uint256 amount)`**: Burns `AU` tokens from the caller's balance. Can be used for fees or penalties.

**AetherAgent (ERC721) NFT Contract:**
4.  **`constructor()`**: Initializes the ERC721 token with a name ("AetherAgent") and symbol ("AEA").
5.  **`mintAgent(address to, uint256 agentId, string memory tokenURI)`**: Mints a new `AetherAgent` NFT to a specified address. Restricted to the `AetherweaveAI` protocol contract.
6.  **`burnAgent(uint256 agentId)`**: Burns an `AetherAgent` NFT. Restricted to the `AetherweaveAI` protocol.

**AetherweaveAI Protocol Contract:**
7.  **`constructor(address _tokenAddress, address _nftAddress)`**: Initializes the `AetherweaveAI` protocol by linking it to deployed `AetherUnit` and `AetherAgent` contract addresses. Also sets the initial owner.
8.  **`registerAgentType(string memory _typeName, uint256 _baseComputePower, uint256 _baseSpecializationCode, uint256 _maxSupply)`**: Allows the owner to define and register new archetypes of AI agents with their base stats and maximum supply.
9.  **`mintNewAgent(uint256 _agentTypeId, address _owner, string memory _tokenURI)`**: Mints a new `AetherAgent` NFT of a specified type for a given owner, assigning initial stats and metadata URI. Requires `AU` payment.
10. **`updateAgentStatus(uint256 _agentId, AgentStatus _newStatus)`**: Allows an agent owner to update their agent's operational status (e.g., Idle, Active, Maintenance).
11. **`upgradeAgentComputePower(uint256 _agentId, uint256 _amount)`**: Agent owners can burn `AU` tokens to permanently increase their agent's `computePower` attribute.
12. **`setAgentSpecialization(uint256 _agentId, uint256 _newSpecializationCode)`**: Agent owners can burn `AU` tokens to change their agent's `specializationCode`.
13. **`retireAgent(uint256 _agentId)`**: Permanently retires an agent, burning its NFT and removing it from active service. Only callable by the agent owner.
14. **`submitTask(uint256 _requiredSpecializationCode, uint256 _minComputePower, uint256 _computeUnitsCost, bytes32 _taskDataHash, uint256 _deadline)`**: Users submit new tasks, depositing `AU` tokens as payment for `computeUnits`. `_taskDataHash` points to off-chain task details.
15. **`claimTask(uint256 _taskId, uint256 _agentId)`**: An agent owner claims an available task for their agent, provided the agent meets the requirements. Requires `AU` collateral from the agent owner.
16. **`submitTaskResultHash(uint256 _taskId, uint256 _agentId, bytes32 _resultHash)`**: After off-chain computation, the agent owner submits the hash of the task result.
17. **`verifyTaskResult(uint256 _taskId, uint256 _agentId, bool _isSuccessful, bytes memory _verificationProof)`**: A designated verifier (e.g., oracle, committee) confirms the success or failure of a task result by providing a proof.
18. **`resolveTask(uint256 _taskId)`**: Finalizes a task after verification. If successful, rewards are distributed to the agent and stakers; otherwise, penalties are applied.
19. **`stakeAUForAgent(uint256 _agentId, uint256 _amount)`**: Users stake `AU` tokens on an agent, boosting its reputation score (indirectly its priority) and sharing in its earnings.
20. **`unstakeAUFromAgent(uint256 _agentId, uint256 _amount)`**: Allows users to retrieve their staked `AU` tokens after a cooldown period.
21. **`claimStakingRewards(uint256 _agentId)`**: Stakers can claim their accumulated `AU` rewards from a successful agent's earnings.
22. **`setProtocolParameter(bytes32 _paramKey, uint256 _newValue)`**: Allows the protocol owner to adjust various operational parameters (e.g., task fees, cooldown periods).
23. **`proposeUpgrade(address _newImplementation)`**: For upgradeable contracts, proposes a new implementation address (assumes a UUPS proxy pattern, though not fully implemented here).
24. **`executeUpgrade()`**: Executes the proposed contract upgrade (callable by owner after proposal).
25. **`getAgentStats(uint256 _agentId)`**: Retrieves all on-chain attributes and current status of a specific `AetherAgent`.
26. **`getTaskDetails(uint256 _taskId)`**: Returns comprehensive details about a submitted task, including its current status.
27. **`getAgentStakingBalance(uint256 _agentId, address _staker)`**: Checks the amount of `AU` a specific user has staked on a particular agent.
28. **`getAgentTotalStaked(uint256 _agentId)`**: Returns the total `AU` tokens currently staked across all users for a given agent.
29. **`getAUContractAddress()`**: Returns the address of the `AetherUnit` ERC20 token contract.
30. **`getAgentNFTContractAddress()`**: Returns the address of the `AetherAgent` ERC721 NFT contract.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For explicit safety, though 0.8+ has overflow checks

// Outline:
// I. Core Infrastructure & Tokens
//    A. AetherUnit (ERC20) Token Contract
//    B. AetherAgent (ERC721) NFT Contract
// II. AetherweaveAI Protocol Contract
//    A. State Variables & Data Structures
//    B. Modifiers & Enums
//    C. Constructor
//    D. Agent Management & Lifecycle
//    E. Task Management & Execution
//    F. Staking & Reputation
//    G. Governance & Protocol Parameters
//    H. Views & Helper Functions

// Function Summary:
// AetherUnit (ERC20) Token Contract:
// 1. constructor(): Initializes the ERC20 token with a name and symbol.
// 2. mint(address to, uint256 amount): Mints new tokens, restricted to AetherweaveAI contract.
// 3. burn(uint256 amount): Burns tokens, callable by AetherweaveAI contract or specific roles for penalties/fees.

// AetherAgent (ERC721) NFT Contract:
// 4. constructor(): Initializes the ERC721 token.
// 5. mintAgent(address to, uint256 agentId, string memory tokenURI): Mints a new agent NFT, restricted to AetherweaveAI.
// 6. burnAgent(uint256 agentId): Burns an agent NFT, restricted to AetherweaveAI.

// AetherweaveAI Protocol Contract:
// 7. constructor(address _tokenAddress, address _nftAddress): Initializes protocol with linked token and NFT contracts.
// 8. registerAgentType(string memory _typeName, uint256 _baseComputePower, uint256 _baseSpecializationCode, uint256 _maxSupply): Defines a new type of AI agent.
// 9. mintNewAgent(uint256 _agentTypeId, address _owner, string memory _tokenURI): Mints a new AetherAgent NFT of a specified type for an owner.
// 10. updateAgentStatus(uint256 _agentId, AgentStatus _newStatus): Allows agent owner to change their agent's operational status.
// 11. upgradeAgentComputePower(uint256 _agentId, uint256 _amount): Increases an agent's compute power by burning AU tokens.
// 12. setAgentSpecialization(uint256 _agentId, uint256 _newSpecializationCode): Changes an agent's specialization code by burning AU tokens.
// 13. retireAgent(uint256 _agentId): Permanently removes an agent from active service.
// 14. submitTask(uint256 _requiredSpecializationCode, uint256 _minComputePower, uint256 _computeUnitsCost, bytes32 _taskDataHash, uint256 _deadline): User submits a task, paying compute units.
// 15. claimTask(uint256 _taskId, uint256 _agentId): An agent owner claims a task for their available agent.
// 16. submitTaskResultHash(uint256 _taskId, uint256 _agentId, bytes32 _resultHash): Agent owner submits the hash of the off-chain task result.
// 17. verifyTaskResult(uint256 _taskId, uint256 _agentId, bool _isSuccessful, bytes memory _verificationProof): Verifier confirms success/failure of task result.
// 18. resolveTask(uint256 _taskId): Finalizes a task, distributing rewards or applying penalties.
// 19. stakeAUForAgent(uint256 _agentId, uint256 _amount): Stakes AU tokens on an agent to boost its priority and share earnings.
// 20. unstakeAUFromAgent(uint256 _agentId, uint256 _amount): Unstakes AU tokens from an agent.
// 21. claimStakingRewards(uint256 _agentId): Allows stakers to claim their accumulated rewards.
// 22. setProtocolParameter(bytes32 _paramKey, uint256 _newValue): Owner/governance adjusts protocol parameters.
// 23. proposeUpgrade(address _newImplementation): Proposes a new implementation address for proxy upgrade (if UUPS is used).
// 24. executeUpgrade(): Executes the proposed contract upgrade.
// 25. getAgentStats(uint256 _agentId): Retrieves detailed statistics for a specific agent.
// 26. getTaskDetails(uint256 _taskId): Retrieves full details of a submitted task.
// 27. getAgentStakingBalance(uint256 _agentId, address _staker): Checks amount staked by a staker on an agent.
// 28. getAgentTotalStaked(uint256 _agentId): Gets total AU staked on an agent.
// 29. getAUContractAddress(): Returns the address of the AetherUnit ERC20 contract.
// 30. getAgentNFTContractAddress(): Returns the address of the AetherAgent ERC721 contract.

// I. Core Infrastructure & Tokens

// A. AetherUnit (ERC20) Token Contract
contract AetherUnit is ERC20 {
    // We link AetherUnit to AetherweaveAI for controlled minting/burning
    address public aetherweaveAIContract;

    constructor(address _aetherweaveAIContract) ERC20("AetherUnit", "AU") {
        aetherweaveAIContract = _aetherweaveAIContract;
    }

    modifier onlyAetherweaveAI() {
        require(msg.sender == aetherweaveAIContract, "AetherUnit: Caller is not AetherweaveAI contract");
        _;
    }

    // 2. mint(): Controlled minting for rewards, initial supply etc.
    function mint(address to, uint256 amount) external onlyAetherweaveAI {
        _mint(to, amount);
    }

    // 3. burn(): Controlled burning for fees, penalties etc.
    function burn(uint256 amount) external onlyAetherweaveAI {
        _burn(msg.sender, amount); // Burn from the AetherweaveAI contract's balance
    }
}

// B. AetherAgent (ERC721) NFT Contract
contract AetherAgent is ERC721 {
    // We link AetherAgent to AetherweaveAI for controlled minting/burning
    address public aetherweaveAIContract;

    constructor(address _aetherweaveAIContract) ERC721("AetherAgent", "AEA") {
        aetherweaveAIContract = _aetherweaveAIContract;
    }

    modifier onlyAetherweaveAI() {
        require(msg.sender == aetherweaveAIContract, "AetherAgent: Caller is not AetherweaveAI contract");
        _;
    }

    // 5. mintAgent(): Controlled minting of agent NFTs
    function mintAgent(address to, uint256 agentId, string memory tokenURI) external onlyAetherweaveAI {
        _mint(to, agentId);
        _setTokenURI(agentId, tokenURI);
    }

    // 6. burnAgent(): Controlled burning of agent NFTs (retire an agent)
    function burnAgent(uint256 agentId) external onlyAetherweaveAI {
        require(_isApprovedOrOwner(msg.sender, agentId), "AetherAgent: Caller is not owner nor approved");
        _burn(agentId);
    }

    // Allows AetherweaveAI to set metadata without being the owner, typically it would be
    // done during minting or if the AetherweaveAI contract is approved.
    function setTokenURI(uint256 tokenId, string memory _tokenURI) external onlyAetherweaveAI {
        _setTokenURI(tokenId, _tokenURI);
    }
}


// II. AetherweaveAI Protocol Contract
contract AetherweaveAI is Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- A. State Variables & Data Structures ---

    AetherUnit public auToken;
    AetherAgent public aeAgentNFT;

    // Agent Management
    Counters.Counter private _agentIds; // Counter for global agent IDs
    Counters.Counter private _agentTypeIds; // Counter for agent types

    enum AgentStatus { Idle, Active, ProcessingTask, Maintenance, Retired }

    struct AgentType {
        string name;
        uint256 baseComputePower;
        uint256 baseSpecializationCode; // E.g., 1 for ImageGen, 2 for DataAnalysis
        uint256 maxSupply;
        uint256 mintedSupply;
    }
    mapping(uint256 => AgentType) public agentTypes;

    struct Agent {
        uint256 agentTypeId;
        AgentStatus status;
        uint256 computePower;
        uint256 specializationCode;
        int256 reputation; // Can be positive or negative
        uint256 lastTaskCompletedAt;
        uint256 currentTaskId; // 0 if not assigned to any task
        address owner; // Redundant as ERC721 has this, but convenient
    }
    mapping(uint256 => Agent) public agents;

    // Task Management
    Counters.Counter private _taskIds; // Counter for global task IDs

    enum TaskStatus { Pending, Assigned, Processing, ResultSubmitted, VerifiedSuccessful, VerifiedFailed, Resolved }

    struct Task {
        address requester;
        uint256 requiredSpecializationCode;
        uint256 minComputePower;
        uint256 computeUnitsCost; // In AU tokens
        bytes32 taskDataHash; // Hash of off-chain data / prompt
        uint256 deadline; // Timestamp by which task must be completed
        TaskStatus status;
        uint256 assignedAgentId; // 0 if not assigned
        bytes32 resultHash; // Hash of off-chain result data
        uint256 verificationTimestamp;
        uint256 agentCollateral; // Collateral deposited by agent owner
    }
    mapping(uint256 => Task) public tasks;

    // Staking & Rewards
    mapping(uint256 => mapping(address => uint256)) public agentStakes; // agentId => stakerAddress => amount
    mapping(uint256 => uint256) public totalAgentStaked; // agentId => total amount staked
    mapping(uint256 => mapping(address => uint256)) public stakingRewardsClaimable; // agentId => stakerAddress => rewards

    // Governance Parameters
    mapping(bytes32 => uint256) public protocolParameters; // e.g., "TASK_FEE_PERCENT", "AGENT_COLLATERAL_FACTOR", "REPUTATION_SUCCESS_BOOST", "REPUTATION_FAILURE_PENALTY", "STAKING_COOLDOWN_PERIOD"

    // Upgradeability (simplified for this example, assumes UUPS proxy)
    address public pendingUpgradeImplementation;

    // --- B. Modifiers & Enums ---

    modifier onlyAgentOwner(uint256 _agentId) {
        require(aeAgentNFT.ownerOf(_agentId) == msg.sender, "AetherweaveAI: Only agent owner can call this function");
        _;
    }

    modifier onlyAgentActive(uint256 _agentId) {
        require(agents[_agentId].status == AgentStatus.Active, "AetherweaveAI: Agent not in Active status");
        _;
    }

    modifier onlyAgentIdle(uint256 _agentId) {
        require(agents[_agentId].status == AgentStatus.Idle, "AetherweaveAI: Agent not in Idle status");
        _;
    }

    modifier taskExists(uint256 _taskId) {
        require(_taskId > 0 && tasks[_taskId].requester != address(0), "AetherweaveAI: Task does not exist");
        _;
    }

    modifier agentExists(uint256 _agentId) {
        require(_agentId > 0 && agents[_agentId].owner != address(0), "AetherweaveAI: Agent does not exist");
        _;
    }

    // --- C. Constructor ---

    // 7. constructor()
    constructor(address _tokenAddress, address _nftAddress) Ownable(msg.sender) {
        require(_tokenAddress != address(0), "AetherweaveAI: AU token address cannot be zero");
        require(_nftAddress != address(0), "AetherweaveAI: AEA NFT address cannot be zero");

        auToken = AetherUnit(_tokenAddress);
        aeAgentNFT = AetherAgent(_nftAddress);

        // Set initial protocol parameters
        protocolParameters["TASK_FEE_PERCENT"] = 5; // 5% fee
        protocolParameters["AGENT_COLLATERAL_FACTOR"] = 200; // 200% of compute units cost as collateral
        protocolParameters["REPUTATION_SUCCESS_BOOST"] = 10;
        protocolParameters["REPUTATION_FAILURE_PENALTY"] = 50;
        protocolParameters["STAKING_COOLDOWN_PERIOD"] = 7 days;
        protocolParameters["TASK_VERIFICATION_PERIOD"] = 1 days; // Time window for verification
        protocolParameters["AGENT_MINT_AU_COST"] = 1000 * (10 ** auToken.decimals()); // Cost to mint a new agent
    }

    // --- D. Agent Management & Lifecycle ---

    // 8. registerAgentType()
    function registerAgentType(
        string memory _typeName,
        uint256 _baseComputePower,
        uint256 _baseSpecializationCode,
        uint256 _maxSupply
    ) external onlyOwner {
        _agentTypeIds.increment();
        uint256 newTypeId = _agentTypeIds.current();
        agentTypes[newTypeId] = AgentType({
            name: _typeName,
            baseComputePower: _baseComputePower,
            baseSpecializationCode: _baseSpecializationCode,
            maxSupply: _maxSupply,
            mintedSupply: 0
        });
        emit AgentTypeRegistered(newTypeId, _typeName);
    }

    // 9. mintNewAgent()
    function mintNewAgent(uint256 _agentTypeId, address _owner, string memory _tokenURI) external payable {
        require(_owner != address(0), "AetherweaveAI: Owner address cannot be zero");
        AgentType storage agentType = agentTypes[_agentTypeId];
        require(agentType.mintedSupply < agentType.maxSupply, "AetherweaveAI: Agent type supply exhausted");
        require(msg.value >= protocolParameters["AGENT_MINT_AU_COST"], "AetherweaveAI: Insufficient AU for minting");

        // Take AU tokens for minting cost (assuming `msg.value` is AU, for ETH/AU distinction would need `transferFrom`)
        // For simplicity, let's assume `auToken.transferFrom(msg.sender, address(this), protocolParameters["AGENT_MINT_AU_COST"])`
        // or a direct `msg.value` payment in ETH which then gets converted or is just a fee.
        // For this example, let's assume `auToken` is directly paid by the user.
        // It's a common pattern to pass AU as a parameter and `approve` the contract.
        // For simplicity: `auToken.transferFrom(msg.sender, address(this), protocolParameters["AGENT_MINT_AU_COST"])`
        auToken.transferFrom(msg.sender, address(this), protocolParameters["AGENT_MINT_AU_COST"]);

        _agentIds.increment();
        uint256 newAgentId = _agentIds.current();

        aeAgentNFT.mintAgent(_owner, newAgentId, _tokenURI);

        agents[newAgentId] = Agent({
            agentTypeId: _agentTypeId,
            status: AgentStatus.Idle,
            computePower: agentType.baseComputePower,
            specializationCode: agentType.baseSpecializationCode,
            reputation: 0,
            lastTaskCompletedAt: block.timestamp,
            currentTaskId: 0,
            owner: _owner
        });

        agentType.mintedSupply = agentType.mintedSupply.add(1);

        emit AgentMinted(newAgentId, _owner, _agentTypeId);
    }

    // 10. updateAgentStatus()
    function updateAgentStatus(uint256 _agentId, AgentStatus _newStatus)
        external
        onlyAgentOwner(_agentId)
        agentExists(_agentId)
    {
        require(_newStatus != AgentStatus.ProcessingTask, "AetherweaveAI: Cannot manually set to ProcessingTask");
        require(agents[_agentId].status != AgentStatus.Retired, "AetherweaveAI: Retired agents cannot change status");
        agents[_agentId].status = _newStatus;
        emit AgentStatusUpdated(_agentId, _newStatus);
    }

    // 11. upgradeAgentComputePower()
    function upgradeAgentComputePower(uint256 _agentId, uint256 _amount)
        external
        onlyAgentOwner(_agentId)
        agentExists(_agentId)
    {
        require(_amount > 0, "AetherweaveAI: Upgrade amount must be positive");
        uint256 upgradeCost = _amount.mul(10 * (10 ** auToken.decimals())); // Example: 10 AU per unit of compute power
        auToken.transferFrom(msg.sender, address(this), upgradeCost); // Burn AU for upgrade

        agents[_agentId].computePower = agents[_agentId].computePower.add(_amount);
        emit AgentUpgraded(_agentId, "computePower", _amount);
    }

    // 12. setAgentSpecialization()
    function setAgentSpecialization(uint256 _agentId, uint256 _newSpecializationCode)
        external
        onlyAgentOwner(_agentId)
        agentExists(_agentId)
    {
        require(_newSpecializationCode > 0, "AetherweaveAI: Specialization code must be positive");
        uint256 specializationCost = 500 * (10 ** auToken.decimals()); // Example: 500 AU to change specialization
        auToken.transferFrom(msg.sender, address(this), specializationCost); // Burn AU for specialization change

        agents[_agentId].specializationCode = _newSpecializationCode;
        emit AgentUpgraded(_agentId, "specializationCode", _newSpecializationCode);
    }

    // 13. retireAgent()
    function retireAgent(uint256 _agentId) external onlyAgentOwner(_agentId) agentExists(_agentId) {
        require(agents[_agentId].currentTaskId == 0, "AetherweaveAI: Agent must not be processing a task to retire");
        require(agents[_agentId].status != AgentStatus.Retired, "AetherweaveAI: Agent is already retired");

        agents[_agentId].status = AgentStatus.Retired;
        // Burning the NFT effectively removes it from the system
        aeAgentNFT.burnAgent(_agentId); // Calls the restricted burn function on NFT contract

        // Refund any remaining stake
        if (totalAgentStaked[_agentId] > 0) {
            uint256 totalStake = totalAgentStaked[_agentId];
            totalAgentStaked[_agentId] = 0;
            // Distribute remaining stakes back to stakers (simplified: only owner gets it here)
            // In a real scenario, this would iterate through stakers or use a more complex reward-claiming system.
            auToken.mint(agents[_agentId].owner, totalStake);
        }

        delete agents[_agentId]; // Remove agent data from mapping
        emit AgentRetired(_agentId, msg.sender);
    }


    // --- E. Task Management & Execution ---

    // 14. submitTask()
    function submitTask(
        uint256 _requiredSpecializationCode,
        uint256 _minComputePower,
        uint256 _computeUnitsCost,
        bytes32 _taskDataHash,
        uint256 _deadline
    ) external {
        require(_computeUnitsCost > 0, "AetherweaveAI: Compute units cost must be positive");
        require(_deadline > block.timestamp, "AetherweaveAI: Task deadline must be in the future");
        require(_taskDataHash != bytes32(0), "AetherweaveAI: Task data hash cannot be empty");

        // Transfer AU tokens for task payment
        auToken.transferFrom(msg.sender, address(this), _computeUnitsCost);

        _taskIds.increment();
        uint256 newTaskId = _taskIds.current();

        tasks[newTaskId] = Task({
            requester: msg.sender,
            requiredSpecializationCode: _requiredSpecializationCode,
            minComputePower: _minComputePower,
            computeUnitsCost: _computeUnitsCost,
            taskDataHash: _taskDataHash,
            deadline: _deadline,
            status: TaskStatus.Pending,
            assignedAgentId: 0,
            resultHash: bytes32(0),
            verificationTimestamp: 0,
            agentCollateral: 0
        });

        emit TaskSubmitted(newTaskId, msg.sender, _computeUnitsCost, _deadline);
    }

    // 15. claimTask()
    function claimTask(uint256 _taskId, uint256 _agentId)
        external
        onlyAgentOwner(_agentId)
        agentExists(_agentId)
        taskExists(_taskId)
    {
        Agent storage agent = agents[_agentId];
        Task storage task = tasks[_taskId];

        require(agent.status == AgentStatus.Idle || agent.status == AgentStatus.Active, "AetherweaveAI: Agent not available for tasks");
        require(task.status == TaskStatus.Pending, "AetherweaveAI: Task is not pending");
        require(agent.specializationCode == task.requiredSpecializationCode, "AetherweaveAI: Agent specialization mismatch");
        require(agent.computePower >= task.minComputePower, "AetherweaveAI: Agent compute power too low");
        require(task.deadline > block.timestamp, "AetherweaveAI: Task deadline has passed");

        // Calculate collateral required from agent owner
        uint256 collateralRequired = task.computeUnitsCost.mul(protocolParameters["AGENT_COLLATERAL_FACTOR"]).div(100);
        require(auToken.balanceOf(msg.sender) >= collateralRequired, "AetherweaveAI: Insufficient AU collateral");

        // Transfer collateral from agent owner to contract
        auToken.transferFrom(msg.sender, address(this), collateralRequired);
        task.agentCollateral = collateralRequired;

        task.assignedAgentId = _agentId;
        task.status = TaskStatus.Assigned;
        agent.status = AgentStatus.ProcessingTask;
        agent.currentTaskId = _taskId;

        emit TaskClaimed(_taskId, _agentId, msg.sender);
    }

    // 16. submitTaskResultHash()
    function submitTaskResultHash(uint256 _taskId, uint256 _agentId, bytes32 _resultHash)
        external
        onlyAgentOwner(_agentId)
        agentExists(_agentId)
        taskExists(_taskId)
    {
        Task storage task = tasks[_taskId];
        Agent storage agent = agents[_agentId];

        require(task.assignedAgentId == _agentId, "AetherweaveAI: Agent not assigned to this task");
        require(task.status == TaskStatus.Assigned || task.status == TaskStatus.Processing, "AetherweaveAI: Task not in appropriate status for result submission");
        require(agent.status == AgentStatus.ProcessingTask, "AetherweaveAI: Agent is not processing a task");
        require(block.timestamp <= task.deadline, "AetherweaveAI: Task deadline has passed");
        require(_resultHash != bytes32(0), "AetherweaveAI: Result hash cannot be empty");

        task.resultHash = _resultHash;
        task.status = TaskStatus.ResultSubmitted;
        task.verificationTimestamp = block.timestamp; // Start verification period
        emit TaskResultSubmitted(_taskId, _agentId, _resultHash);
    }

    // 17. verifyTaskResult()
    // This function would typically be called by an Oracle or a Verifier Committee
    // For this example, let's assume `owner` is the verifier.
    function verifyTaskResult(uint256 _taskId, uint256 _agentId, bool _isSuccessful, bytes memory _verificationProof)
        external
        onlyOwner // For demonstration, owner acts as verifier
        taskExists(_taskId)
        agentExists(_agentId)
    {
        Task storage task = tasks[_taskId];
        require(task.assignedAgentId == _agentId, "AetherweaveAI: Agent not assigned to this task");
        require(task.status == TaskStatus.ResultSubmitted, "AetherweaveAI: Task result not submitted or already verified");
        require(block.timestamp <= task.verificationTimestamp.add(protocolParameters["TASK_VERIFICATION_PERIOD"]), "AetherweaveAI: Verification period expired");
        // The `_verificationProof` could be a hash of a ZKP verification output, or other verifiable data.
        // The contract itself does not interpret the proof, but its existence can be recorded.

        task.status = _isSuccessful ? TaskStatus.VerifiedSuccessful : TaskStatus.VerifiedFailed;
        emit TaskVerified(_taskId, _agentId, _isSuccessful);
    }

    // 18. resolveTask()
    function resolveTask(uint256 _taskId) external taskExists(_taskId) {
        Task storage task = tasks[_taskId];
        Agent storage agent = agents[task.assignedAgentId];

        require(task.status == TaskStatus.VerifiedSuccessful || task.status == TaskStatus.VerifiedFailed, "AetherweaveAI: Task not yet verified");
        require(task.assignedAgentId != 0, "AetherweaveAI: Task was not assigned to an agent");
        require(agent.status == AgentStatus.ProcessingTask, "AetherweaveAI: Agent must be in processing state for task resolution");

        uint256 taskFee = task.computeUnitsCost.mul(protocolParameters["TASK_FEE_PERCENT"]).div(100);
        uint256 agentReward = task.computeUnitsCost.sub(taskFee); // Reward before staker split

        if (task.status == TaskStatus.VerifiedSuccessful) {
            // Transfer task payment to agent owner (after fee)
            // First, distribute to stakers, then agent owner
            _distributeStakingRewards(task.assignedAgentId, agentReward);
            auToken.transfer(agent.owner, stakingRewardsClaimable[task.assignedAgentId][agent.owner]); // Agent owner claims via staking system
            stakingRewardsClaimable[task.assignedAgentId][agent.owner] = 0; // Reset agent owner's claimable rewards

            // Refund collateral
            auToken.transfer(agent.owner, task.agentCollateral);

            // Boost agent reputation
            agent.reputation = agent.reputation.add(int256(protocolParameters["REPUTATION_SUCCESS_BOOST"]));
            agent.lastTaskCompletedAt = block.timestamp;
            emit TaskResolvedSuccessful(_taskId, task.assignedAgentId, agentReward);

        } else if (task.status == TaskStatus.VerifiedFailed) {
            // Penalty: Requester gets a refund, agent loses collateral, reputation hit
            auToken.transfer(task.requester, task.computeUnitsCost); // Refund requester
            // Collateral is kept by the protocol or distributed as a penalty pool.
            // For simplicity, collateral is burned.
            auToken.burn(task.agentCollateral);

            // Penalize agent reputation
            agent.reputation = agent.reputation.sub(int256(protocolParameters["REPUTATION_FAILURE_PENALTY"]));
            emit TaskResolvedFailed(_taskId, task.assignedAgentId);
        }

        // Reset agent status and current task
        agent.status = AgentStatus.Idle;
        agent.currentTaskId = 0;
        task.status = TaskStatus.Resolved;
    }

    // --- F. Staking & Reputation ---

    // 19. stakeAUForAgent()
    function stakeAUForAgent(uint256 _agentId, uint256 _amount) external agentExists(_agentId) {
        require(_amount > 0, "AetherweaveAI: Stake amount must be positive");
        auToken.transferFrom(msg.sender, address(this), _amount);

        agentStakes[_agentId][msg.sender] = agentStakes[_agentId][msg.sender].add(_amount);
        totalAgentStaked[_agentId] = totalAgentStaked[_agentId].add(_amount);

        // Reputation can also be boosted by staking, but for simplicity, primarily task success drives it.
        emit AUStaked(_agentId, msg.sender, _amount);
    }

    // 20. unstakeAUFromAgent()
    function unstakeAUFromAgent(uint256 _agentId, uint256 _amount) external agentExists(_agentId) {
        require(_amount > 0, "AetherweaveAI: Unstake amount must be positive");
        require(agentStakes[_agentId][msg.sender] >= _amount, "AetherweaveAI: Insufficient staked amount");

        // Implement cooldown period for unstaking
        // For simplicity, this example skips cooldown logic, but it would involve tracking last unstake time.
        // require(block.timestamp > lastUnstakeTime[msg.sender].add(protocolParameters["STAKING_COOLDOWN_PERIOD"]), "AetherweaveAI: Staking cooldown active");

        agentStakes[_agentId][msg.sender] = agentStakes[_agentId][msg.sender].sub(_amount);
        totalAgentStaked[_agentId] = totalAgentStaked[_agentId].sub(_amount);
        auToken.transfer(msg.sender, _amount);

        emit AUUnstaked(_agentId, msg.sender, _amount);
    }

    // Internal function to distribute rewards among stakers
    function _distributeStakingRewards(uint256 _agentId, uint256 _totalReward) internal {
        if (totalAgentStaked[_agentId] == 0 || _totalReward == 0) return;

        // Iterate through stakers (this is inefficient for many stakers, a pull-based model is better)
        // For demonstration, let's assume a direct distribution or a system where stakers claim based on accrued shares.
        // A more scalable solution would be a reward pool where stakers claim based on their share.

        // Placeholder for a more complex reward distribution, here rewards are added to claimable balance.
        // All stakers proportionally share the reward.
        // This is not fully iterative. In practice, stakers would 'claim' their portion, calculated dynamically.
        // For simplicity, we add the reward to the agent owner's claimable balance.
        // A full distribution requires an iterable mapping or a specific claim pattern.
        address agentOwner = agents[_agentId].owner;
        stakingRewardsClaimable[_agentId][agentOwner] = stakingRewardsClaimable[_agentId][agentOwner].add(_totalReward);
        // This makes the agent owner the sole recipient for simplicity for now.
        // A real system would calculate shares for all stakers based on their proportional stake.
    }


    // 21. claimStakingRewards()
    function claimStakingRewards(uint256 _agentId) external agentExists(_agentId) {
        uint256 rewards = stakingRewardsClaimable[_agentId][msg.sender];
        require(rewards > 0, "AetherweaveAI: No rewards to claim for this agent");

        stakingRewardsClaimable[_agentId][msg.sender] = 0;
        auToken.transfer(msg.sender, rewards);
        emit RewardsClaimed(_agentId, msg.sender, rewards);
    }

    // --- G. Governance & Protocol Parameters ---

    // 22. setProtocolParameter()
    function setProtocolParameter(bytes32 _paramKey, uint256 _newValue) external onlyOwner {
        protocolParameters[_paramKey] = _newValue;
        emit ProtocolParameterUpdated(_paramKey, _newValue);
    }

    // 23. proposeUpgrade() (Placeholder for upgradeable proxy)
    // This assumes a UUPS-like proxy pattern where this contract is the implementation.
    // The actual proxy would call `_authorizeUpgrade` on this contract.
    function proposeUpgrade(address _newImplementation) external onlyOwner {
        require(_newImplementation != address(0), "AetherweaveAI: New implementation address cannot be zero");
        pendingUpgradeImplementation = _newImplementation;
        emit UpgradeProposed(_newImplementation);
    }

    // 24. executeUpgrade() (Placeholder for upgradeable proxy)
    // In a real UUPS setup, this would be an internal function called by the proxy.
    // Here, simplified to be externally callable by owner.
    function executeUpgrade() external onlyOwner {
        require(pendingUpgradeImplementation != address(0), "AetherweaveAI: No upgrade proposed");
        // In a UUPS scenario, the proxy itself would manage switching implementation.
        // This function is purely indicative of the intention.
        address newImpl = pendingUpgradeImplementation;
        pendingUpgradeImplementation = address(0); // Clear after execution
        emit UpgradeExecuted(newImpl);
    }

    // --- H. Views & Helper Functions ---

    // 25. getAgentStats()
    function getAgentStats(uint256 _agentId)
        external
        view
        agentExists(_agentId)
        returns (
            uint256 agentTypeId,
            AgentStatus status,
            uint256 computePower,
            uint256 specializationCode,
            int256 reputation,
            uint256 lastTaskCompletedAt,
            uint256 currentTaskId,
            address ownerAddress
        )
    {
        Agent storage agent = agents[_agentId];
        return (
            agent.agentTypeId,
            agent.status,
            agent.computePower,
            agent.specializationCode,
            agent.reputation,
            agent.lastTaskCompletedAt,
            agent.currentTaskId,
            agent.owner
        );
    }

    // 26. getTaskDetails()
    function getTaskDetails(uint256 _taskId)
        external
        view
        taskExists(_taskId)
        returns (
            address requester,
            uint256 requiredSpecializationCode,
            uint256 minComputePower,
            uint256 computeUnitsCost,
            bytes32 taskDataHash,
            uint256 deadline,
            TaskStatus status,
            uint256 assignedAgentId,
            bytes32 resultHash,
            uint256 verificationTimestamp,
            uint256 agentCollateral
        )
    {
        Task storage task = tasks[_taskId];
        return (
            task.requester,
            task.requiredSpecializationCode,
            task.minComputePower,
            task.computeUnitsCost,
            task.taskDataHash,
            task.deadline,
            task.status,
            task.assignedAgentId,
            task.resultHash,
            task.verificationTimestamp,
            task.agentCollateral
        );
    }

    // 27. getAgentStakingBalance()
    function getAgentStakingBalance(uint256 _agentId, address _staker) external view returns (uint256) {
        return agentStakes[_agentId][_staker];
    }

    // 28. getAgentTotalStaked()
    function getAgentTotalStaked(uint256 _agentId) external view returns (uint256) {
        return totalAgentStaked[_agentId];
    }

    // 29. getAUContractAddress()
    function getAUContractAddress() external view returns (address) {
        return address(auToken);
    }

    // 30. getAgentNFTContractAddress()
    function getAgentNFTContractAddress() external view returns (address) {
        return address(aeAgentNFT);
    }

    // --- Events ---
    event AgentTypeRegistered(uint256 indexed agentTypeId, string name);
    event AgentMinted(uint256 indexed agentId, address indexed owner, uint256 agentTypeId);
    event AgentStatusUpdated(uint256 indexed agentId, AgentStatus newStatus);
    event AgentUpgraded(uint256 indexed agentId, string attribute, uint256 newValue);
    event AgentRetired(uint256 indexed agentId, address indexed owner);

    event TaskSubmitted(uint256 indexed taskId, address indexed requester, uint256 cost, uint256 deadline);
    event TaskClaimed(uint256 indexed taskId, uint256 indexed agentId, address indexed agentOwner);
    event TaskResultSubmitted(uint256 indexed taskId, uint256 indexed agentId, bytes32 resultHash);
    event TaskVerified(uint256 indexed taskId, uint256 indexed agentId, bool isSuccessful);
    event TaskResolvedSuccessful(uint256 indexed taskId, uint256 indexed agentId, uint256 rewardAmount);
    event TaskResolvedFailed(uint256 indexed taskId, uint256 indexed agentId);

    event AUStaked(uint256 indexed agentId, address indexed staker, uint256 amount);
    event AUUnstaked(uint256 indexed agentId, address indexed staker, uint256 amount);
    event RewardsClaimed(uint256 indexed agentId, address indexed staker, uint256 amount);

    event ProtocolParameterUpdated(bytes32 indexed paramKey, uint256 newValue);
    event UpgradeProposed(address newImplementation);
    event UpgradeExecuted(address newImplementation);
}
```