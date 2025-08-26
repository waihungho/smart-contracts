This smart contract, "ChronoForge: Autonomous Agent & Dynamic Achievement Network," introduces a novel ecosystem where users can mint and manage AI-driven (or rather, "intent-driven") autonomous agents represented as Dynamic NFTs (DNFTs). These agents can be configured to perform specific on-chain tasks, participate in quests, and evolve their traits based on their performance. Successful agent operations contribute to the owner's non-transferable "Chrono Reputation" score, fostering a gamified, skill-based on-chain identity.

The contract integrates concepts from:
*   **Dynamic NFTs (DNFTs):** Agent NFTs evolve their traits on-chain based on performance.
*   **Soulbound Tokens (SBTs) / Reputation Systems:** A non-transferable "Chrono Reputation" score for users, tied to their agents' success.
*   **Autonomous Agents / Intent-Based Architecture:** Users define agent "strategies" (intents), and the contract facilitates delegated execution of agent tasks.
*   **Gamification / Quests:** A system for proposing and claiming rewards for specific agent tasks.
*   **Liquid Staking / Energy Systems:** Agents require staked "energy" tokens to operate, with performance-based rewards and penalties.
*   **Decentralized Governance (Basic):** A simple proposal/vote mechanism for critical parameters.
*   **Oracle Integration (Conceptual):** Hooks for external data, crucial for agents reacting to off-chain events.

---

## ChronoForge: Autonomous Agent & Dynamic Achievement Network

### Outline & Function Summary

**I. Core Infrastructure & Access Control**
1.  `constructor`: Initializes the contract, sets the `OWNER_ROLE` and `ADMIN_ROLE`, and deploys the `AgentEnergyToken`.
2.  `pauseContract()`: Pauses all critical contract functionalities during emergencies.
3.  `unpauseContract()`: Resumes contract operation after a pause.
4.  `setAdminRole(address _newAdmin)`: Grants `ADMIN_ROLE` to a new address.
5.  `setOracleAddress(address _oracleAddress)`: Sets the address of a trusted oracle provider.

**II. Agent NFT Management (Dynamic NFTs)**
6.  `createAgentNFT(string memory _agentName, bytes32 _initialStrategyId, uint256 _energyStakeAmount)`: Mints a new Agent DNFT for the caller, initializes its traits, and requires an initial stake of `AgentEnergyToken`.
7.  `upgradeAgentTrait(uint256 _tokenId, AgentTraitType _traitType, uint256 _boostAmount)`: Increases a specific trait's value for a given Agent DNFT, reflecting improved performance.
8.  `degradeAgentTrait(uint256 _tokenId, AgentTraitType _traitType, uint256 _penaltyAmount)`: Decreases a specific trait's value for a given Agent DNFT, reflecting poor performance or failures.
9.  `setAgentStrategy(uint256 _tokenId, bytes32 _newStrategyId)`: Updates the operating strategy or "intent" for an agent, changing its defined behavior.
10. `getAgentData(uint256 _tokenId)`: Retrieves all the detailed information and current traits for a specified agent.
11. `getAgentTrait(uint256 _tokenId, AgentTraitType _traitType)`: Fetches the current value of a single specific trait for an agent.

**III. Agent Operation & Interaction**
12. `rechargeAgentEnergy(uint256 _tokenId, uint256 _amount)`: Allows an agent owner to add more `AgentEnergyToken` to their agent's stake, extending its operational capacity.
13. `withdrawAgentEnergy(uint256 _tokenId, uint256 _amount)`: Allows an agent owner to withdraw `AgentEnergyToken` from their agent's stake, provided it doesn't fall below a minimum threshold.
14. `registerAgentPerformance(uint256 _tokenId, uint256 _rewardEnergy, uint256 _reputationBoost)`: Records a successful agent operation, upgrades traits, grants `AgentEnergyToken` rewards, and boosts the owner's Chrono Reputation.
15. `reportAgentFailure(uint256 _tokenId, uint256 _penaltyEnergy, uint256 _reputationPenalty)`: Records an agent's failure, degrades traits, penalizes `AgentEnergyToken`, and reduces the owner's Chrono Reputation.
16. `executeAgentTask(uint256 _tokenId, address _targetContract, bytes memory _calldata)`: Allows a whitelisted executor (or the owner) to trigger a generic transaction on behalf of the agent, enabling complex automated behaviors.
17. `proposeAgentQuest(string memory _questDescription, uint256 _rewardAmount, bytes32 _requiredStrategyId, uint256 _duration)`: Allows anyone to propose a quest for agents to complete, with a specified reward.
18. `claimQuestReward(uint256 _questId, uint256 _tokenId)`: Allows an agent owner to claim the reward for their agent successfully completing an active quest.

**IV. Reputation System (SBT-like)**
19. `getChronoReputation(address _user)`: Retrieves the non-transferable "Chrono Reputation" score for a given user.
20. `getAgentReputationBoost(uint256 _tokenId)`: Calculates the reputation multiplier or bonus provided by a specific agent based on its current traits.

**V. Governance & Admin**
21. `proposeParameterChange(bytes32 _parameterName, uint256 _newValue, string memory _description)`: Allows a user with sufficient Chrono Reputation to propose changes to contract parameters (e.g., minimum energy stake, epoch duration).
22. `voteOnProposal(uint256 _proposalId, bool _for)`: Allows users with Chrono Reputation to cast votes on active proposals.
23. `executeProposal(uint256 _proposalId)`: Executes a proposal that has reached the required consensus and voting period.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Dummy ERC20 for Agent Energy - In a real scenario, this would be a separate contract
// or an existing token. For this example, it's nested for simplicity and deployment.
contract AgentEnergyToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("Agent Energy", "AET") {
        _mint(msg.sender, initialSupply);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}

contract ChronoForge is ERC721Enumerable, Pausable, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- Enums and Structs ---

    enum AgentTraitType {
        Efficiency,      // How efficiently it uses energy
        Reliability,     // Likelihood of success in tasks
        Adaptability,    // Ability to switch strategies or handle new tasks
        ProcessingPower  // Speed/complexity of tasks it can handle
    }

    struct AgentTrait {
        uint256 value;   // Current value of the trait
        uint256 max;     // Maximum possible value for the trait
    }

    struct Agent {
        string name;
        address owner;
        bytes32 currentStrategyId; // Identifier for the agent's current operating strategy/intent
        mapping(AgentTraitType => AgentTrait) traits; // Dynamic traits of the agent
        uint256 energyBalance; // Staked AgentEnergyToken balance
        uint256 creationTime;
        bool exists; // To check if agent exists without iterating
    }

    struct Quest {
        string description;
        address proposer;
        uint256 rewardAmount; // Amount of AgentEnergyToken
        bytes32 requiredStrategyId; // Only agents with this strategy can complete
        uint256 deadline;
        bool completed;
        uint256 tokenIdCompleter; // Who completed it
    }

    // Basic on-chain governance proposal structure
    struct Proposal {
        string description;
        bytes32 parameterName; // e.g., "minEnergyStake", "epochDuration"
        uint256 newValue;
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
        bool passed;
    }

    // --- State Variables ---

    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _questIdCounter;
    Counters.Counter private _proposalIdCounter;

    // Agent data storage
    mapping(uint256 => Agent) public agents;
    // User reputation (SBT-like, non-transferable)
    mapping(address => uint256) public chronoReputation;
    // Whitelisted addresses that can trigger agent actions on behalf of owners (e.g., keeper networks)
    mapping(address => bool) public agentExecutors;
    // Registered quests
    mapping(uint256 => Quest) public quests;
    // Registered proposals
    mapping(uint256 => Proposal) public proposals;
    // Map of users who voted on a proposal
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    // Admin role for specific operations
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    mapping(address => bool) private _admins;

    // Token for agent energy
    IERC20 public immutable agentEnergyToken;

    // Oracle address for external data feeds (conceptual, actual integration would be more complex)
    address public oracleAddress;

    // Configuration parameters
    uint256 public minEnergyStake = 100 * 10**18; // Minimum AET to create an agent
    uint256 public minAgentEnergyBalance = 50 * 10**18; // Minimum AET to keep an agent active
    uint256 public reputationBoostFactor = 100; // Multiplier for reputation gains
    uint256 public reputationPenaltyFactor = 50; // Multiplier for reputation losses
    uint256 public proposalQuorumPercentage = 51; // 51% of total reputation for a proposal to pass
    uint256 public votingPeriodDuration = 3 days; // Duration for voting on proposals
    uint256 public proposalMinReputationToPropose = 1000; // Minimum ChronoReputation to propose

    // --- Events ---

    event AgentCreated(uint256 indexed tokenId, address indexed owner, string name, bytes32 initialStrategyId);
    event AgentTraitUpgraded(uint256 indexed tokenId, AgentTraitType traitType, uint256 oldValue, uint256 newValue);
    event AgentTraitDegraded(uint256 indexed tokenId, AgentTraitType traitType, uint256 oldValue, uint256 newValue);
    event AgentStrategyUpdated(uint256 indexed tokenId, bytes32 oldStrategyId, bytes32 newStrategyId);
    event AgentEnergyRecharged(uint256 indexed tokenId, uint256 amount, uint256 newBalance);
    event AgentEnergyWithdrawn(uint256 indexed tokenId, uint256 amount, uint256 newBalance);
    event AgentPerformanceRegistered(uint256 indexed tokenId, address indexed owner, uint256 rewardEnergy, uint256 reputationBoost);
    event AgentFailureReported(uint256 indexed tokenId, address indexed owner, uint256 penaltyEnergy, uint256 reputationPenalty);
    event AgentTaskExecuted(uint256 indexed tokenId, address indexed executor, address targetContract);
    event QuestProposed(uint256 indexed questId, address indexed proposer, uint256 rewardAmount, bytes32 requiredStrategyId, uint256 deadline);
    event QuestClaimed(uint256 indexed questId, uint256 indexed tokenId, address indexed claimer);
    event ChronoReputationUpdated(address indexed user, uint256 oldValue, uint256 newValue);
    event OracleAddressSet(address indexed oldAddress, address indexed newAddress);
    event AdminRoleGranted(address indexed admin);
    event AdminRoleRevoked(address indexed admin);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, bytes32 parameterName, uint256 newValue);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool _for);
    event ProposalExecuted(uint256 indexed proposalId, bool passed);

    // --- Modifiers ---

    modifier onlyAdmin() {
        require(_admins[msg.sender] || msg.sender == owner(), "ChronoForge: Caller is not an admin");
        _;
    }

    modifier onlyAgentOwner(uint256 _tokenId) {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "ChronoForge: Caller is not agent owner or approved");
        _;
    }

    modifier onlyAgentExecutorOrOwner(uint256 _tokenId) {
        require(agentExecutors[msg.sender] || _isApprovedOrOwner(msg.sender, _tokenId), "ChronoForge: Caller not authorized to execute for agent");
        _;
    }

    // --- Constructor ---

    constructor() ERC721("ChronoForge Agent", "CFA") Ownable(msg.sender) {
        // Deploy a new AgentEnergyToken contract and set its address
        agentEnergyToken = new AgentEnergyToken(10_000_000 * 10**18); // Mint 10M AET to ChronoForge owner for initial distribution/rewards
        _admins[msg.sender] = true; // Owner is also an admin initially
        emit AdminRoleGranted(msg.sender);
    }

    // --- I. Core Infrastructure & Access Control ---

    function pauseContract() public onlyAdmin whenNotPaused {
        _pause();
    }

    function unpauseContract() public onlyAdmin whenPaused {
        _unpause();
    }

    function setAdminRole(address _newAdmin, bool _hasRole) public onlyOwner {
        if (_hasRole) {
            _admins[_newAdmin] = true;
            emit AdminRoleGranted(_newAdmin);
        } else {
            _admins[_newAdmin] = false;
            emit AdminRoleRevoked(_newAdmin);
        }
    }

    function setAgentExecutor(address _executor, bool _canExecute) public onlyAdmin {
        agentExecutors[_executor] = _canExecute;
    }

    function setOracleAddress(address _oracleAddress) public onlyAdmin {
        address oldAddress = oracleAddress;
        oracleAddress = _oracleAddress;
        emit OracleAddressSet(oldAddress, _oracleAddress);
    }

    // --- II. Agent NFT Management (Dynamic NFTs) ---

    function createAgentNFT(string memory _agentName, bytes32 _initialStrategyId, uint256 _energyStakeAmount) public payable whenNotPaused {
        require(_energyStakeAmount >= minEnergyStake, "ChronoForge: Initial energy stake too low");
        require(agentEnergyToken.transferFrom(msg.sender, address(this), _energyStakeAmount), "ChronoForge: AET transfer failed");

        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        Agent storage newAgent = agents[newTokenId];
        newAgent.name = _agentName;
        newAgent.owner = msg.sender;
        newAgent.currentStrategyId = _initialStrategyId;
        newAgent.creationTime = block.timestamp;
        newAgent.exists = true;
        newAgent.energyBalance = _energyStakeAmount;

        // Initialize base traits
        newAgent.traits[AgentTraitType.Efficiency].value = 100;
        newAgent.traits[AgentTraitType.Efficiency].max = 1000;
        newAgent.traits[AgentTraitType.Reliability].value = 100;
        newAgent.traits[AgentTraitType.Reliability].max = 1000;
        newAgent.traits[AgentTraitType.Adaptability].value = 100;
        newAgent.traits[AgentTraitType.Adaptability].max = 1000;
        newAgent.traits[AgentTraitType.ProcessingPower].value = 100;
        newAgent.traits[AgentTraitType.ProcessingPower].max = 1000;

        _safeMint(msg.sender, newTokenId);
        emit AgentCreated(newTokenId, msg.sender, _agentName, _initialStrategyId);
    }

    function upgradeAgentTrait(uint256 _tokenId, AgentTraitType _traitType, uint256 _boostAmount) public onlyAgentOwner(_tokenId) whenNotPaused {
        Agent storage agent = agents[_tokenId];
        require(agent.exists, "ChronoForge: Agent does not exist");
        
        uint256 oldValue = agent.traits[_traitType].value;
        uint256 newValue = oldValue.add(_boostAmount);
        if (newValue > agent.traits[_traitType].max) {
            newValue = agent.traits[_traitType].max;
        }
        agent.traits[_traitType].value = newValue;
        emit AgentTraitUpgraded(_tokenId, _traitType, oldValue, newValue);
    }

    function degradeAgentTrait(uint256 _tokenId, AgentTraitType _traitType, uint256 _penaltyAmount) public onlyAgentOwner(_tokenId) whenNotPaused {
        Agent storage agent = agents[_tokenId];
        require(agent.exists, "ChronoForge: Agent does not exist");

        uint256 oldValue = agent.traits[_traitType].value;
        uint256 newValue = oldValue.sub(_penaltyAmount, "ChronoForge: Trait value cannot go below zero");
        agent.traits[_traitType].value = newValue;
        emit AgentTraitDegraded(_tokenId, _traitType, oldValue, newValue);
    }

    function setAgentStrategy(uint256 _tokenId, bytes32 _newStrategyId) public onlyAgentOwner(_tokenId) whenNotPaused {
        Agent storage agent = agents[_tokenId];
        require(agent.exists, "ChronoForge: Agent does not exist");

        bytes32 oldStrategyId = agent.currentStrategyId;
        agent.currentStrategyId = _newStrategyId;
        emit AgentStrategyUpdated(_tokenId, oldStrategyId, _newStrategyId);
    }

    function getAgentData(uint256 _tokenId) public view returns (
        string memory name,
        address owner,
        bytes32 currentStrategyId,
        uint256 energyBalance,
        uint256 efficiency,
        uint256 reliability,
        uint256 adaptability,
        uint256 processingPower,
        uint256 creationTime
    ) {
        Agent storage agent = agents[_tokenId];
        require(agent.exists, "ChronoForge: Agent does not exist");

        return (
            agent.name,
            agent.owner,
            agent.currentStrategyId,
            agent.energyBalance,
            agent.traits[AgentTraitType.Efficiency].value,
            agent.traits[AgentTraitType.Reliability].value,
            agent.traits[AgentTraitType.Adaptability].value,
            agent.traits[AgentTraitType.ProcessingPower].value,
            agent.creationTime
        );
    }

    function getAgentTrait(uint256 _tokenId, AgentTraitType _traitType) public view returns (uint256 value, uint256 max) {
        Agent storage agent = agents[_tokenId];
        require(agent.exists, "ChronoForge: Agent does not exist");
        return (agent.traits[_traitType].value, agent.traits[_traitType].max);
    }

    // --- III. Agent Operation & Interaction ---

    function rechargeAgentEnergy(uint256 _tokenId, uint256 _amount) public onlyAgentOwner(_tokenId) whenNotPaused {
        Agent storage agent = agents[_tokenId];
        require(agent.exists, "ChronoForge: Agent does not exist");
        require(agentEnergyToken.transferFrom(msg.sender, address(this), _amount), "ChronoForge: AET transfer failed");

        agent.energyBalance = agent.energyBalance.add(_amount);
        emit AgentEnergyRecharged(_tokenId, _amount, agent.energyBalance);
    }

    function withdrawAgentEnergy(uint256 _tokenId, uint256 _amount) public onlyAgentOwner(_tokenId) whenNotPaused {
        Agent storage agent = agents[_tokenId];
        require(agent.exists, "ChronoForge: Agent does not exist");
        require(agent.energyBalance.sub(_amount, "ChronoForge: Insufficient energy to withdraw") >= minAgentEnergyBalance, "ChronoForge: Withdrawal would leave agent below minimum energy");

        agent.energyBalance = agent.energyBalance.sub(_amount);
        require(agentEnergyToken.transfer(msg.sender, _amount), "ChronoForge: AET withdrawal failed");
        emit AgentEnergyWithdrawn(_tokenId, _amount, agent.energyBalance);
    }

    function registerAgentPerformance(uint256 _tokenId, uint256 _rewardEnergy, uint256 _reputationBoost) public onlyAgentOwner(_tokenId) whenNotPaused {
        Agent storage agent = agents[_tokenId];
        require(agent.exists, "ChronoForge: Agent does not exist");

        // Award energy
        agent.energyBalance = agent.energyBalance.add(_rewardEnergy);
        
        // Boost owner's reputation
        _updateChronoReputation(agent.owner, _reputationBoost.mul(reputationBoostFactor).div(100)); // Scaled boost
        
        // Optionally, upgrade a trait based on performance type (e.g., if specific function, could specify trait)
        // For simplicity, we'll just demonstrate general performance here
        // In a real system, success in a specific "task type" would boost relevant trait
        upgradeAgentTrait(_tokenId, AgentTraitType.Reliability, 5); // Example: small reliability boost

        emit AgentPerformanceRegistered(_tokenId, agent.owner, _rewardEnergy, _reputationBoost);
    }

    function reportAgentFailure(uint256 _tokenId, uint256 _penaltyEnergy, uint256 _reputationPenalty) public onlyAgentOwner(_tokenId) whenNotPaused {
        Agent storage agent = agents[_tokenId];
        require(agent.exists, "ChronoForge: Agent does not exist");
        
        // Penalize energy
        agent.energyBalance = agent.energyBalance.sub(_penaltyEnergy, "ChronoForge: Not enough energy for penalty");
        
        // Penalize owner's reputation
        _updateChronoReputation(agent.owner, _reputationPenalty.mul(reputationPenaltyFactor).div(100).mul(uint256(type(int256).min))); // Scaled penalty

        // Optionally, degrade a trait
        degradeAgentTrait(_tokenId, AgentTraitType.Reliability, 10); // Example: larger reliability degradation

        emit AgentFailureReported(_tokenId, agent.owner, _penaltyEnergy, _reputationPenalty);
    }

    // Allows a whitelisted executor (e.g., a keeper bot) or the owner to trigger a call
    // from the ChronoForge contract as if it were the agent, targeting another contract.
    // This is a powerful "delegated execution" or "intent-based" mechanism.
    function executeAgentTask(uint256 _tokenId, address _targetContract, bytes memory _calldata) public payable onlyAgentExecutorOrOwner(_tokenId) whenNotPaused {
        Agent storage agent = agents[_tokenId];
        require(agent.exists, "ChronoForge: Agent does not exist");
        require(agent.energyBalance >= minAgentEnergyBalance, "ChronoForge: Agent energy too low to execute task");
        
        // Agent pays a small energy fee for execution
        agent.energyBalance = agent.energyBalance.sub(1 * 10**18, "ChronoForge: Insufficient energy for task execution fee"); // Example fee

        // The actual execution happens via `call` from this contract
        (bool success, bytes memory result) = _targetContract.call(_calldata);
        require(success, string(abi.encodePacked("ChronoForge: Agent task execution failed: ", result)));

        emit AgentTaskExecuted(_tokenId, msg.sender, _targetContract);
    }

    function proposeAgentQuest(
        string memory _questDescription,
        uint256 _rewardAmount,
        bytes32 _requiredStrategyId,
        uint256 _duration
    ) public payable whenNotPaused {
        require(agentEnergyToken.transferFrom(msg.sender, address(this), _rewardAmount), "ChronoForge: Quest reward deposit failed");
        
        _questIdCounter.increment();
        uint256 newQuestId = _questIdCounter.current();

        quests[newQuestId] = Quest({
            description: _questDescription,
            proposer: msg.sender,
            rewardAmount: _rewardAmount,
            requiredStrategyId: _requiredStrategyId,
            deadline: block.timestamp.add(_duration),
            completed: false,
            tokenIdCompleter: 0
        });

        emit QuestProposed(newQuestId, msg.sender, _rewardAmount, _requiredStrategyId, quests[newQuestId].deadline);
    }

    function claimQuestReward(uint256 _questId, uint256 _tokenId) public onlyAgentOwner(_tokenId) whenNotPaused {
        Quest storage quest = quests[_questId];
        require(quest.rewardAmount > 0, "ChronoForge: Quest does not exist");
        require(!quest.completed, "ChronoForge: Quest already completed");
        require(block.timestamp <= quest.deadline, "ChronoForge: Quest deadline passed");

        Agent storage agent = agents[_tokenId];
        require(agent.exists, "ChronoForge: Agent does not exist");
        require(agent.currentStrategyId == quest.requiredStrategyId, "ChronoForge: Agent strategy does not match quest requirement");
        
        // In a real scenario, there would be a verification step here
        // e.g., an oracle proof, or a successful `executeAgentTask` linked to this quest.
        // For this example, we'll assume `msg.sender` asserts completion.

        quest.completed = true;
        quest.tokenIdCompleter = _tokenId;

        // Reward the agent with energy
        agent.energyBalance = agent.energyBalance.add(quest.rewardAmount);
        
        // Boost owner's reputation
        _updateChronoReputation(agent.owner, quest.rewardAmount.div(10**18).mul(reputationBoostFactor)); // Reputation based on reward magnitude
        
        emit QuestClaimed(_questId, _tokenId, agent.owner);
    }

    // --- IV. Reputation System (SBT-like) ---

    function getChronoReputation(address _user) public view returns (uint256) {
        return chronoReputation[_user];
    }

    // Internal function to update reputation, not directly callable by users
    function _updateChronoReputation(address _user, int256 _change) internal {
        uint256 currentRep = chronoReputation[_user];
        uint256 newRep;

        if (_change >= 0) {
            newRep = currentRep.add(uint256(_change));
        } else {
            newRep = currentRep.sub(uint256(-_change), "ChronoForge: Reputation cannot go below zero");
        }
        chronoReputation[_user] = newRep;
        emit ChronoReputationUpdated(_user, currentRep, newRep);
    }

    function getAgentReputationBoost(uint256 _tokenId) public view returns (uint256) {
        Agent storage agent = agents[_tokenId];
        require(agent.exists, "ChronoForge: Agent does not exist");

        // Example: Reputation boost is a weighted sum of traits
        uint256 totalTraitValue = agent.traits[AgentTraitType.Efficiency].value
            .add(agent.traits[AgentTraitType.Reliability].value)
            .add(agent.traits[AgentTraitType.Adaptability].value)
            .add(agent.traits[AgentTraitType.ProcessingPower].value);
        
        // This could be a complex formula. For now, a simple sum scaled.
        return totalTraitValue.div(10); // Every 10 points of total traits gives 1 reputation point
    }

    // --- V. Governance & Admin (Decentralized Parameters) ---

    function proposeParameterChange(
        bytes32 _parameterName,
        uint256 _newValue,
        string memory _description
    ) public whenNotPaused {
        require(chronoReputation[msg.sender] >= proposalMinReputationToPropose, "ChronoForge: Not enough reputation to propose");

        _proposalIdCounter.increment();
        uint256 newProposalId = _proposalIdCounter.current();

        proposals[newProposalId] = Proposal({
            description: _description,
            parameterName: _parameterName,
            newValue: _newValue,
            voteStartTime: block.timestamp,
            voteEndTime: block.timestamp.add(votingPeriodDuration),
            yesVotes: 0,
            noVotes: 0,
            executed: false,
            passed: false
        });

        emit ProposalCreated(newProposalId, msg.sender, _parameterName, _newValue);
    }

    function voteOnProposal(uint256 _proposalId, bool _for) public whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.voteStartTime > 0, "ChronoForge: Proposal does not exist");
        require(block.timestamp >= proposal.voteStartTime && block.timestamp <= proposal.voteEndTime, "ChronoForge: Voting period not active");
        require(!hasVoted[_proposalId][msg.sender], "ChronoForge: Already voted on this proposal");
        require(chronoReputation[msg.sender] > 0, "ChronoForge: No reputation to vote");

        hasVoted[_proposalId][msg.sender] = true;
        if (_for) {
            proposal.yesVotes = proposal.yesVotes.add(chronoReputation[msg.sender]);
        } else {
            proposal.noVotes = proposal.noVotes.add(chronoReputation[msg.sender]);
        }
        emit VoteCast(_proposalId, msg.sender, _for);
    }

    function executeProposal(uint256 _proposalId) public onlyAdmin whenNotPaused { // onlyAdmin for security in parameter application
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.voteStartTime > 0, "ChronoForge: Proposal does not exist");
        require(block.timestamp > proposal.voteEndTime, "ChronoForge: Voting period not ended");
        require(!proposal.executed, "ChronoForge: Proposal already executed");

        uint256 totalVotes = proposal.yesVotes.add(proposal.noVotes);
        bool passed = false;
        if (totalVotes > 0 && proposal.yesVotes.mul(100).div(totalVotes) >= proposalQuorumPercentage) {
            passed = true;
        }
        
        proposal.passed = passed;
        proposal.executed = true;

        if (passed) {
            _applyParameterChange(proposal.parameterName, proposal.newValue);
        }
        emit ProposalExecuted(_proposalId, passed);
    }

    // Internal function to apply parameter changes
    function _applyParameterChange(bytes32 _parameterName, uint256 _newValue) internal {
        if (_parameterName == keccak256("minEnergyStake")) {
            minEnergyStake = _newValue;
        } else if (_parameterName == keccak256("minAgentEnergyBalance")) {
            minAgentEnergyBalance = _newValue;
        } else if (_parameterName == keccak256("reputationBoostFactor")) {
            reputationBoostFactor = _newValue;
        } else if (_parameterName == keccak256("reputationPenaltyFactor")) {
            reputationPenaltyFactor = _newValue;
        } else if (_parameterName == keccak256("proposalQuorumPercentage")) {
            require(_newValue <= 100, "Quorum cannot exceed 100%");
            proposalQuorumPercentage = _newValue;
        } else if (_parameterName == keccak256("votingPeriodDuration")) {
            votingPeriodDuration = _newValue;
        } else if (_parameterName == keccak256("proposalMinReputationToPropose")) {
            proposalMinReputationToPropose = _newValue;
        }
        // Add more parameters here as needed
    }

    // --- ERC721 Metadata (conceptual for dynamic NFTs) ---
    // A fully dynamic NFT would typically use an off-chain service (e.g., IPFS)
    // to serve metadata, which queries the contract for the latest trait values.
    // This `tokenURI` provides a placeholder link.
    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://CHRONOFORGE_METADATA_BASE_URI/"; // Placeholder
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        
        // In a real system, this URI would point to an API endpoint that generates
        // JSON metadata on-the-fly, based on `getAgentData(_tokenId)`.
        // Example: "https://myapi.com/agent_metadata/{tokenId}"
        string memory base = _baseURI();
        return string(abi.encodePacked(base, Strings.toString(_tokenId), ".json"));
    }
}
```