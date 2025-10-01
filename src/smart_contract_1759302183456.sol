Here's the smart contract suite for the "EvoluAgent Protocol," incorporating advanced concepts like dynamic NFTs, verifiable computation (simulated), a reputation system, tokenomics, staking, and a simplified governance model. The contract aims for creativity and is designed to be distinct from typical open-source projects by combining these elements into a unique ecosystem for AI agents.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol"; // For tokenOfOwnerByIndex in governance
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // For withdrawProtocolFees

// Outline and Function Summary:
//
// This smart contract suite, "EvoluAgent Protocol", envisions a decentralized ecosystem for dynamic AI agents (EvoluAgents).
// Users can mint these agents as NFTs, which possess evolving attributes and reputation.
// The protocol facilitates a marketplace where requesters can post AI tasks, and agent owners can assign their
// agents to complete these tasks. Successful task completion, verified by an oracle via submitted proofs,
// leads to attribute improvements, reputation gains, and EvoluCoin rewards for the agents and their owners.
// Agents can also be staked with EvoluCoin to enhance their reliability and earn passive rewards, contributing
// to the network's overall capacity. A simplified governance mechanism allows agent owners to propose and vote
// on protocol parameter changes.
//
// Contracts Included:
// 1. EvoluCoin: An ERC20 token used for task payments, staking, and rewards within the EvoluAgent ecosystem.
// 2. EvoluAgent: An ERC721-compliant (specifically ERC721URIStorage and ERC721Enumerable) NFT representing an AI agent.
//                 It stores dynamic attributes and reputation which are updated by the EvoluAgentProtocol contract.
// 3. EvoluAgentProtocol: The core contract orchestrating task assignments, proof submissions, oracle verification,
//                          reward distribution, agent evolution, staking, and protocol governance.
//
// --- EvoluAgentProtocol Function Summary (30 Functions) ---
//
// I. Core Setup & Admin: Manages fundamental protocol settings and administrative actions.
//    1. constructor(address _initialOracle, address _evolucCoinAddress): Initializes the protocol, sets up roles,
//       links the EvoluCoin contract, and deploys the EvoluAgent NFT contract.
//    2. setProtocolParameter(bytes32 _paramKey, uint256 _newValue): Allows `DEFAULT_ADMIN_ROLE` to update key protocol parameters.
//    3. setOracleAddress(address _newOracle): Sets or changes the trusted oracle address.
//    4. grantRole(bytes32 role, address account): Inherited from AccessControl; grants a role.
//    5. revokeRole(bytes32 role, address account): Inherited from AccessControl; revokes a role.
//    6. pause(): Inherited from Pausable; pauses the contract in emergencies.
//    7. unpause(): Inherited from Pausable; unpauses the contract.
//    8. withdrawProtocolFees(address _tokenAddress, uint256 _amount): Allows `DEFAULT_ADMIN_ROLE` to withdraw accumulated protocol fees.
//
// II. Agent Interaction: Manages the lifecycle and state of EvoluAgent NFTs.
//    9. mintAgent(string memory _name, string memory _tokenURI): Mints a new EvoluAgent NFT for the caller, requiring an initial EvoluCoin deposit.
//   10. getAgentDetails(uint256 _agentId): Retrieves all dynamic attributes, reputation, and owner of an EvoluAgent.
//   11. burnAgent(uint256 _agentId): Allows an agent owner to destroy their EvoluAgent NFT, unstaking any attached EVC first.
//
// III. Task Management: Orchestrates the creation, assignment, proof submission, and completion of AI tasks.
//   12. requestTask(string memory _description, uint256 _requiredProcessingPower, uint256 _rewardAmount, uint256 _deadline):
//       Allows users to create new AI tasks, locking up EvoluCoin rewards and a protocol fee.
//   13. assignAgentToTask(uint256 _taskId, uint256 _agentId): Allows an agent owner to assign their EvoluAgent to an open task,
//       checking eligibility based on agent attributes and staked EVC.
//   14. submitTaskProof(uint256 _taskId, uint256 _agentId, bytes32 _proofHash): An agent owner submits an off-chain computation proof hash.
//   15. verifyAndCompleteTask(uint256 _taskId, bool _isSuccessful): Callable only by `ORACLE_ROLE`. Verifies the proof (off-chain),
//       resolves the task, distributes rewards, and updates agent attributes/reputation based on success or failure.
//   16. cancelTask(uint256 _taskId): Allows the task requester to cancel their unassigned task and reclaim all deposited tokens.
//
// IV. Staking & Rewards: Manages EvoluCoin staking by agent owners to boost agent reliability and earn passive income.
//   17. stakeAgent(uint256 _agentId, uint256 _amount): Agent owner stakes EvoluCoin to their agent, triggering reward claim for previous period.
//   18. unstakeAgent(uint256 _agentId, uint256 _amount): Agent owner unstakes EvoluCoin from their agent, triggering reward claim for previous period.
//   19. claimStakingRewards(uint256 _agentId): Allows agent owners to claim accrued staking rewards, minting them if the protocol has the MINTER_ROLE.
//
// V. Governance (Simplified): Enables a basic proposal and voting mechanism for protocol parameter changes, weighted by staked EVC.
//   20. proposeParameterChange(bytes32 _paramKey, uint256 _newValue): Proposes a new parameter change, requiring a minimum personal stake and a fee.
//   21. voteOnProposal(uint256 _proposalId, bool _support): Allows agent owners to vote on active proposals, with voting power based on their total staked EVC.
//   22. executeProposal(uint256 _proposalId): Executes a proposal if it has passed its voting period and met quorum and majority thresholds.
//
// VI. Getters / Views: Provides read-only access to various protocol states and data.
//   23. getTask(uint256 _taskId): Returns detailed information about a specific task.
//   24. getAgentStakingBalance(uint256 _agentId): Returns the total EvoluCoin staked to a given agent.
//   25. getEvoluCoinAddress(): Returns the address of the EvoluCoin ERC20 contract.
//   26. getEvoluAgentAddress(): Returns the address of the EvoluAgent ERC721 contract.
//   27. getProtocolParameter(bytes32 _paramKey): Returns the current value of a specified protocol parameter.
//   28. getTotalStakedTokens(): Returns the total amount of EvoluCoin currently staked across all agents in the protocol.
//   29. getCurrentTaskId(): Returns the last assigned task ID.
//   30. getCurrentProposalId(): Returns the last assigned proposal ID.

// --- Dependency Contracts ---

/// @title EvoluCoin - ERC20 Token for the EvoluAgent Protocol
/// @notice This contract defines the native utility token for the EvoluAgent ecosystem.
///         It is burnable and has a MINTER_ROLE for the protocol to issue staking rewards.
contract EvoluCoin is ERC20Burnable, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor() ERC20("EvoluCoin", "EVC") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        // The deployer of EvoluCoin initially has the MINTER_ROLE.
        // This role must be granted to the EvoluAgentProtocol contract by the deployer
        // after the EvoluAgentProtocol is deployed, to enable reward minting.
        _grantRole(MINTER_ROLE, msg.sender); 
    }

    /// @notice Mints new tokens to a specified address. Only callable by MINTER_ROLE.
    /// @param to The address to mint tokens to.
    /// @param amount The amount of tokens to mint.
    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }
}

/// @title EvoluAgent - Dynamic NFT for AI Agents
/// @notice This contract defines the ERC721 NFTs representing AI agents.
///         Agents have dynamic attributes and a reputation score, which can be updated
///         only by the EvoluAgentProtocol contract. It includes ERC721Enumerable
///         for use in governance calculations.
contract EvoluAgent is ERC721URIStorage, ERC721Enumerable, AccessControl {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // Role for the EvoluAgentProtocol contract to mint new agents
    bytes32 public constant AGENT_MINTER_ROLE = keccak256("AGENT_MINTER_ROLE");
    // Role for the EvoluAgentProtocol contract to update agent attributes
    bytes32 public constant ATTRIBUTE_UPDATER_ROLE = keccak256("ATTRIBUTE_UPDATER_ROLE");

    struct AgentAttributes {
        string name;
        uint256 processingPower; // Ability to handle complex tasks
        uint256 creativity;      // Quality of output for generative tasks
        uint256 reliability;     // Consistency and success rate
        uint256 taskCompletionCount; // Total tasks successfully completed
        uint256 totalReputationGain; // Accumulated reputation from tasks
    }

    mapping(uint256 => AgentAttributes) private _agentAttributes;
    mapping(uint256 => uint256) private _agentReputation; // Global reputation score, derived from attributes and tasks

    modifier onlyAttributeUpdater() {
        require(hasRole(ATTRIBUTE_UPDATER_ROLE, _msgSender()), "EvoluAgent: Must have ATTRIBUTE_UPDATER_ROLE");
        _;
    }

    constructor() ERC721("EvoluAgent", "EVAL") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        // The EvoluAgentProtocol contract will be granted AGENT_MINTER_ROLE and ATTRIBUTE_UPDATER_ROLE
    }

    /// @notice Mints a new EvoluAgent NFT and initializes its attributes.
    /// @dev Only callable by addresses with AGENT_MINTER_ROLE (expected to be EvoluAgentProtocol).
    /// @param to The address of the new agent owner.
    /// @param name The initial name of the agent.
    /// @param tokenURI The URI for the agent's metadata.
    /// @return The tokenId of the newly minted agent.
    function mint(address to, string memory name, string memory tokenURI)
        public
        onlyRole(AGENT_MINTER_ROLE)
        returns (uint256)
    {
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();
        _mint(to, newTokenId);
        _setTokenURI(newTokenId, tokenURI);

        _agentAttributes[newTokenId] = AgentAttributes({
            name: name,
            processingPower: 10, // Initial value
            creativity: 10,      // Initial value
            reliability: 10,     // Initial value
            taskCompletionCount: 0,
            totalReputationGain: 0
        });
        _agentReputation[newTokenId] = 100; // Initial reputation
        return newTokenId;
    }

    /// @notice Updates an agent's attributes and reputation.
    /// @dev This function is designed to be called by the EvoluAgentProtocol contract.
    ///      Only callable by addresses with ATTRIBUTE_UPDATER_ROLE.
    /// @param tokenId The ID of the agent to update.
    /// @param newProcessingPower The new processing power.
    /// @param newCreativity The new creativity score.
    /// @param newReliability The new reliability score.
    /// @param reputationDelta The change in reputation (can be positive or negative).
    /// @param taskCompleted A boolean indicating if a task was successfully completed, increments count if true.
    function _updateAgentAttributes(
        uint256 tokenId,
        uint256 newProcessingPower,
        uint256 newCreativity,
        uint256 newReliability,
        int256 reputationDelta,
        bool taskCompleted
    ) public onlyAttributeUpdater {
        require(_exists(tokenId), "EvoluAgent: Agent does not exist");
        AgentAttributes storage agent = _agentAttributes[tokenId];
        
        agent.processingPower = newProcessingPower;
        agent.creativity = newCreativity;
        agent.reliability = newReliability;
        if (taskCompleted) {
            agent.taskCompletionCount += 1;
        }

        if (reputationDelta > 0) {
            agent.totalReputationGain += uint256(reputationDelta);
        }

        int256 currentReputation = int256(_agentReputation[tokenId]);
        currentReputation += reputationDelta;
        if (currentReputation < 0) currentReputation = 0; // Reputation cannot go below zero
        _agentReputation[tokenId] = uint256(currentReputation);

        emit AgentAttributesUpdated(
            tokenId,
            newProcessingPower,
            newCreativity,
            newReliability,
            _agentReputation[tokenId]
        );
    }

    /// @notice Retrieves the attributes of a specific agent.
    /// @param tokenId The ID of the agent.
    /// @return AgentAttributes struct containing all attributes.
    function getAttributes(uint256 tokenId)
        public
        view
        returns (
            string memory name,
            uint256 processingPower,
            uint256 creativity,
            uint256 reliability,
            uint256 taskCompletionCount,
            uint256 totalReputationGain
        )
    {
        require(_exists(tokenId), "EvoluAgent: Agent does not exist");
        AgentAttributes storage agent = _agentAttributes[tokenId];
        return (
            agent.name,
            agent.processingPower,
            agent.creativity,
            agent.reliability,
            agent.taskCompletionCount,
            agent.totalReputationGain
        );
    }

    /// @notice Retrieves the current reputation score of a specific agent.
    /// @param tokenId The ID of the agent.
    /// @return The agent's current reputation score.
    function getReputation(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "EvoluAgent: Agent does not exist");
        return _agentReputation[tokenId];
    }

    /// @notice Burns an EvoluAgent NFT.
    /// @dev Only the owner of the token or an approved address can burn it.
    /// @param tokenId The ID of the agent to burn.
    function burn(uint256 tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "EvoluAgent: Not owner or approved");
        _burn(tokenId);
        delete _agentAttributes[tokenId];
        delete _agentReputation[tokenId];
        emit AgentBurned(tokenId, _msgSender());
    }

    // The following functions are overrides required by Solidity for ERC721Enumerable
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721URIStorage, ERC721Enumerable, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _update(address to, uint256 tokenId, address auth) internal virtual override(ERC721, ERC721Enumerable) returns (address) {
        return super._update(to, tokenId, auth);
    }

    event AgentAttributesUpdated(
        uint256 indexed tokenId,
        uint256 processingPower,
        uint256 creativity,
        uint256 reliability,
        uint256 reputation
    );
    event AgentBurned(uint256 indexed tokenId, address indexed owner);
}

// --- Main Protocol Contract ---

/// @title EvoluAgentProtocol - Core Logic for Dynamic AI Agent Ecosystem
/// @notice This contract manages tasks, agent evolution, staking, rewards, and governance.
contract EvoluAgentProtocol is AccessControl, Pausable, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _taskIdCounter;
    Counters.Counter private _proposalIdCounter;

    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");

    // Linked Contracts
    EvoluCoin public evoluCoin;
    EvoluAgent public evoluAgent;

    // Protocol Parameters (can be updated via governance)
    mapping(bytes32 => uint256) public protocolParameters;

    // Task Management
    enum TaskStatus {
        Open,
        Assigned,
        ProofSubmitted,
        CompletedSuccess,
        CompletedFailure,
        Canceled
    }

    struct Task {
        uint256 id;
        address requester;
        string description;
        uint256 requiredProcessingPower;
        uint256 rewardAmount;
        uint256 deadline;
        uint256 assignedAgentId; // 0 if not assigned
        address assignedAgentOwner; // owner when assigned
        bytes32 proofHash;       // Hash of the off-chain proof
        TaskStatus status;
        uint256 createdAt;
    }
    mapping(uint256 => Task) public tasks;

    // Staking
    struct AgentStaking {
        uint256 stakedAmount;
        uint256 lastRewardClaimTime; // Timestamp of last reward claim or stake action
    }
    mapping(uint256 => AgentStaking) public agentStaking; // agentId => AgentStaking
    uint256 public totalStakedEVC; // Total EVC staked across all agents in the protocol

    // Governance
    enum ProposalStatus {
        Pending, // Not yet started voting (unused as proposals are active immediately)
        Active,
        Succeeded,
        Failed,
        Executed
    }

    struct Proposal {
        uint256 id;
        address proposer;
        bytes32 paramKey;
        uint256 newValue;
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // Voter address => voted
        ProposalStatus status;
    }
    mapping(uint256 => Proposal) public proposals;

    // Events
    event AgentMinted(uint256 indexed tokenId, address indexed owner, string name);
    event TaskRequested(uint256 indexed taskId, address indexed requester, uint256 rewardAmount, uint256 deadline);
    event AgentAssigned(uint256 indexed taskId, uint256 indexed agentId, address indexed agentOwner);
    event TaskProofSubmitted(uint256 indexed taskId, uint256 indexed agentId, bytes32 proofHash);
    event TaskCompleted(uint256 indexed taskId, uint256 indexed agentId, bool successful, uint256 rewardPaid);
    event AgentStaked(uint256 indexed agentId, address indexed owner, uint256 amount);
    event AgentUnstaked(uint256 indexed agentId, address indexed owner, uint256 amount);
    event StakingRewardsClaimed(uint256 indexed agentId, address indexed owner, uint256 rewardAmount);
    event ProtocolParameterUpdated(bytes32 indexed paramKey, uint256 newValue);
    event ProposalCreated(uint256 indexed proposalId, bytes32 paramKey, uint256 newValue, address indexed proposer);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event TaskCanceled(uint256 indexed taskId, address indexed requester);

    constructor(address _initialOracle, address _evolucCoinAddress) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ORACLE_ROLE, _initialOracle);

        evoluCoin = EvoluCoin(_evolucCoinAddress);

        // Deploy EvoluAgent contract and grant necessary roles
        evoluAgent = new EvoluAgent();
        evoluAgent.grantRole(evoluAgent.AGENT_MINTER_ROLE(), address(this));
        evoluAgent.grantRole(evoluAgent.ATTRIBUTE_UPDATER_ROLE(), address(this));

        // Initialize default protocol parameters
        protocolParameters[keccak256("TASK_FEE_PERCENT")] = 5; // 5% of task reward goes to protocol
        protocolParameters[keccak256("MINT_AGENT_FEE")] = 100 * 10 ** evoluCoin.decimals(); // 100 EVC
        protocolParameters[keccak256("STAKING_REWARD_RATE_PER_SECOND")] = 1000; // Represents 0.001 EVC per staked EVC per day (approx)
        protocolParameters[keccak256("STAKING_REWARD_RATE_DENOMINATOR")] = 86400 * 1000; // Denominator for the rate, 86400 seconds in a day
        protocolParameters[keccak256("GOVERNANCE_VOTING_PERIOD")] = 3 days;
        protocolParameters[keccak256("GOVERNANCE_QUORUM_PERCENT")] = 2; // 2% of total staked EVC to pass
        protocolParameters[keccak256("GOVERNANCE_MIN_STAKE_TO_PROPOSE")] = 1000 * 10 ** evoluCoin.decimals(); // 1000 EVC required for proposer
        protocolParameters[keccak256("GOVERNANCE_PROPOSAL_FEE")] = 50 * 10 ** evoluCoin.decimals(); // 50 EVC fee for proposing
    }

    /// @notice Sets or updates a protocol parameter. Only callable by `DEFAULT_ADMIN_ROLE`.
    /// @dev This function can be superseded by governance proposals for decentralized updates.
    /// @param _paramKey The keccak256 hash of the parameter name (e.g., `keccak256("TASK_FEE_PERCENT")`).
    /// @param _newValue The new value for the parameter.
    function setProtocolParameter(bytes32 _paramKey, uint256 _newValue) public onlyRole(DEFAULT_ADMIN_ROLE) {
        protocolParameters[_paramKey] = _newValue;
        emit ProtocolParameterUpdated(_paramKey, _newValue);
    }

    /// @notice Sets the address of the trusted oracle. Only callable by `DEFAULT_ADMIN_ROLE`.
    /// @param _newOracle The address of the new oracle.
    function setOracleAddress(address _newOracle) public onlyRole(DEFAULT_ADMIN_ROLE) {
        // Revoke the role from the old oracle if one was set
        if (hasRole(ORACLE_ROLE, getRoleMember(ORACLE_ROLE, 0))) { // Check if there's any oracle member
            _revokeRole(ORACLE_ROLE, getRoleMember(ORACLE_ROLE, 0)); 
        }
        _grantRole(ORACLE_ROLE, _newOracle);
    }

    /// @notice Allows the `DEFAULT_ADMIN_ROLE` to withdraw protocol fees collected.
    /// @dev This function should be used carefully and potentially be replaced by a more robust treasury management system.
    /// @param _tokenAddress The address of the token to withdraw (e.g., EvoluCoin).
    /// @param _amount The amount to withdraw.
    function withdrawProtocolFees(address _tokenAddress, uint256 _amount) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_amount > 0, "Protocol: Withdraw amount must be positive");
        IERC20 token = IERC20(_tokenAddress);
        require(token.balanceOf(address(this)) >= _amount, "Protocol: Insufficient balance");
        token.transfer(msg.sender, _amount);
    }

    /// @notice Mints a new EvoluAgent NFT. Requires `MINT_AGENT_FEE` in EvoluCoin.
    /// @param _name The initial name of the agent.
    /// @param _tokenURI The URI for the agent's metadata.
    /// @return The ID of the newly minted agent.
    function mintAgent(string memory _name, string memory _tokenURI) public whenNotPaused nonReentrant returns (uint256) {
        uint256 mintFee = protocolParameters[keccak256("MINT_AGENT_FEE")];
        require(evoluCoin.transferFrom(msg.sender, address(this), mintFee), "Protocol: Mint fee payment failed");

        uint256 newTokenId = evoluAgent.mint(msg.sender, _name, _tokenURI);
        emit AgentMinted(newTokenId, msg.sender, _name);
        return newTokenId;
    }

    /// @notice Retrieves detailed information about an EvoluAgent.
    /// @param _agentId The ID of the agent.
    /// @return name Agent's name.
    /// @return processingPower Agent's processing power.
    /// @return creativity Agent's creativity.
    /// @return reliability Agent's reliability.
    /// @return taskCompletionCount Total tasks completed.
    /// @return totalReputationGain Accumulated reputation gain.
    /// @return reputation Overall reputation score.
    /// @return owner The current owner of the agent.
    function getAgentDetails(uint256 _agentId)
        public
        view
        returns (
            string memory name,
            uint256 processingPower,
            uint256 creativity,
            uint256 reliability,
            uint256 taskCompletionCount,
            uint256 totalReputationGain,
            uint256 reputation,
            address owner
        )
    {
        (name, processingPower, creativity, reliability, taskCompletionCount, totalReputationGain) = evoluAgent.getAttributes(_agentId);
        reputation = evoluAgent.getReputation(_agentId);
        owner = evoluAgent.ownerOf(_agentId);
    }

    /// @notice Allows an agent owner to burn their EvoluAgent NFT.
    /// @param _agentId The ID of the agent to burn.
    function burnAgent(uint256 _agentId) public whenNotPaused nonReentrant {
        require(evoluAgent.ownerOf(_agentId) == msg.sender, "Protocol: Not agent owner");
        _unstakeAgentInternal(_agentId, agentStaking[_agentId].stakedAmount); // Unstake any staked EVC first
        evoluAgent.burn(_agentId);
    }

    /// @notice Creates a new AI task request. Requires `rewardAmount` in EvoluCoin.
    /// @param _description A description of the task.
    /// @param _requiredProcessingPower The minimum processing power required for the agent.
    /// @param _rewardAmount The EvoluCoin reward for completing the task.
    /// @param _deadline The timestamp by which the task must be completed.
    /// @return The ID of the newly created task.
    function requestTask(
        string memory _description,
        uint256 _requiredProcessingPower,
        uint256 _rewardAmount,
        uint256 _deadline
    ) public whenNotPaused nonReentrant returns (uint256) {
        require(_rewardAmount > 0, "Task: Reward must be positive");
        require(_deadline > block.timestamp, "Task: Deadline must be in the future");
        
        // Transfer reward and protocol fee from requester
        uint256 taskFeePercent = protocolParameters[keccak256("TASK_FEE_PERCENT")];
        uint256 protocolFee = (_rewardAmount * taskFeePercent) / 100;
        uint256 totalPayment = _rewardAmount + protocolFee;

        require(evoluCoin.transferFrom(msg.sender, address(this), totalPayment), "Protocol: Task payment failed");

        _taskIdCounter.increment();
        uint256 newTaskId = _taskIdCounter.current();

        tasks[newTaskId] = Task({
            id: newTaskId,
            requester: msg.sender,
            description: _description,
            requiredProcessingPower: _requiredProcessingPower,
            rewardAmount: _rewardAmount,
            deadline: _deadline,
            assignedAgentId: 0,
            assignedAgentOwner: address(0),
            proofHash: bytes32(0),
            status: TaskStatus.Open,
            createdAt: block.timestamp
        });

        emit TaskRequested(newTaskId, msg.sender, _rewardAmount, _deadline);
        return newTaskId;
    }

    /// @notice Assigns an EvoluAgent to an open task.
    /// @dev Only the agent's owner can assign it. Agent must meet `requiredProcessingPower` and have staked EVC.
    /// @param _taskId The ID of the task to assign.
    /// @param _agentId The ID of the agent to assign.
    function assignAgentToTask(uint256 _taskId, uint256 _agentId) public whenNotPaused nonReentrant {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.Open, "Task: Not an open task");
        require(task.deadline > block.timestamp, "Task: Deadline passed");
        require(evoluAgent.ownerOf(_agentId) == msg.sender, "Protocol: Not agent owner");

        (, uint256 agentProcessingPower,,,,,) = evoluAgent.getAttributes(_agentId);
        require(agentProcessingPower >= task.requiredProcessingPower, "Agent: Insufficient processing power");
        
        // Agent must also be staked to ensure reliability and availability
        require(agentStaking[_agentId].stakedAmount > 0, "Agent: Must have EVC staked to accept tasks");

        task.assignedAgentId = _agentId;
        task.assignedAgentOwner = msg.sender;
        task.status = TaskStatus.Assigned;

        emit AgentAssigned(_taskId, _agentId, msg.sender);
    }

    /// @notice Submits an off-chain computation proof hash for an assigned task.
    /// @dev Only the assigned agent's owner can submit a proof.
    /// @param _taskId The ID of the task.
    /// @param _agentId The ID of the agent that completed the task.
    /// @param _proofHash The keccak256 hash of the off-chain proof.
    function submitTaskProof(uint256 _taskId, uint256 _agentId, bytes32 _proofHash) public whenNotPaused nonReentrant {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.Assigned, "Task: Not in assigned state");
        require(task.assignedAgentId == _agentId, "Task: Agent not assigned to this task");
        require(task.assignedAgentOwner == msg.sender, "Task: Not the assigned agent owner");
        require(task.deadline > block.timestamp, "Task: Deadline passed for proof submission");
        require(_proofHash != bytes32(0), "Task: Proof hash cannot be empty");

        task.proofHash = _proofHash;
        task.status = TaskStatus.ProofSubmitted;

        emit TaskProofSubmitted(_taskId, _agentId, _proofHash);
    }

    /// @notice Verifies the submitted proof (off-chain) and resolves the task.
    /// @dev Only callable by `ORACLE_ROLE`. Distributes rewards and updates agent attributes.
    /// @param _taskId The ID of the task to verify.
    /// @param _isSuccessful Boolean indicating if the proof was successfully verified.
    function verifyAndCompleteTask(uint256 _taskId, bool _isSuccessful) public onlyRole(ORACLE_ROLE) whenNotPaused nonReentrant {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.ProofSubmitted, "Task: Proof not submitted or already resolved");
        // Oracle can verify even if deadline passed to avoid DOS of oracle, but still within reason.
        // For simplicity, keeping deadline check here.
        require(task.deadline > block.timestamp, "Task: Task deadline expired before oracle verification");

        task.status = _isSuccessful ? TaskStatus.CompletedSuccess : TaskStatus.CompletedFailure;

        uint256 agentId = task.assignedAgentId;
        address agentOwner = task.assignedAgentOwner;

        // Retrieve current agent attributes
        (
            string memory name,
            uint256 processingPower,
            uint256 creativity,
            uint256 reliability,
            uint256 taskCompletionCount,
            uint256 totalReputationGain
        ) = evoluAgent.getAttributes(agentId);

        // Update agent attributes and distribute rewards
        if (_isSuccessful) {
            uint256 reward = task.rewardAmount;
            require(evoluCoin.transfer(agentOwner, reward), "Protocol: Reward transfer failed");

            // Agent attribute evolution based on task completion
            evoluAgent._updateAgentAttributes(
                agentId,
                processingPower + 1, // Slight improvement in processing power
                creativity,
                reliability + 1,     // Slight improvement in reliability
                5,                   // +5 reputation for success
                true                 // Increment task completion count
            );
            emit TaskCompleted(_taskId, agentId, true, reward);
        } else {
            // Penalize agent for failure (e.g., fraudulent or incorrect proof)
            evoluAgent._updateAgentAttributes(
                agentId,
                processingPower,
                creativity,
                reliability > 1 ? reliability - 1 : 0, // Decrease reliability, minimum 0
                -10, // -10 reputation for failure
                false // Do not increment task completion count
            );
            // Optionally: Refund task reward to requester, penalize agent owner's stake, etc.
            // For now, assume reward is lost by agent and kept by protocol if verification fails
            emit TaskCompleted(_taskId, agentId, false, 0);
        }
    }

    /// @notice Allows the task requester to cancel their task if it's still open and not assigned.
    /// @param _taskId The ID of the task to cancel.
    function cancelTask(uint256 _taskId) public whenNotPaused nonReentrant {
        Task storage task = tasks[_taskId];
        require(task.requester == msg.sender, "Task: Only requester can cancel");
        require(task.status == TaskStatus.Open, "Task: Can only cancel open tasks");
        require(task.deadline > block.timestamp, "Task: Cannot cancel after deadline");

        task.status = TaskStatus.Canceled;

        // Refund the entire amount (reward + fee) to the requester
        uint256 taskFeePercent = protocolParameters[keccak256("TASK_FEE_PERCENT")];
        uint256 protocolFee = (task.rewardAmount * taskFeePercent) / 100;
        uint256 totalRefund = task.rewardAmount + protocolFee;

        require(evoluCoin.transfer(task.requester, totalRefund), "Protocol: Refund failed");

        emit TaskCanceled(_taskId, msg.sender);
    }

    /// @notice Stakes EvoluCoin to an agent, boosting its reliability and earning staking rewards.
    /// @param _agentId The ID of the agent to stake for.
    /// @param _amount The amount of EvoluCoin to stake.
    function stakeAgent(uint256 _agentId, uint256 _amount) public whenNotPaused nonReentrant {
        require(evoluAgent.ownerOf(_agentId) == msg.sender, "Staking: Not agent owner");
        require(_amount > 0, "Staking: Amount must be positive");

        _claimStakingRewardsInternal(_agentId); // Claim any outstanding rewards before modifying stake

        require(evoluCoin.transferFrom(msg.sender, address(this), _amount), "Staking: EVC transfer failed");

        agentStaking[_agentId].stakedAmount += _amount;
        agentStaking[_agentId].lastRewardClaimTime = block.timestamp;
        totalStakedEVC += _amount;

        emit AgentStaked(_agentId, msg.sender, _amount);
    }

    /// @notice Unstakes EvoluCoin from an agent.
    /// @param _agentId The ID of the agent to unstake from.
    /// @param _amount The amount of EvoluCoin to unstake.
    function unstakeAgent(uint256 _agentId, uint256 _amount) public whenNotPaused nonReentrant {
        require(evoluAgent.ownerOf(_agentId) == msg.sender, "Unstaking: Not agent owner");
        require(_amount > 0, "Unstaking: Amount must be positive");
        require(agentStaking[_agentId].stakedAmount >= _amount, "Unstaking: Insufficient staked amount");

        _claimStakingRewardsInternal(_agentId); // Claim any outstanding rewards before modifying stake
        _unstakeAgentInternal(_agentId, _amount);
        
        emit AgentUnstaked(_agentId, msg.sender, _amount);
    }

    /// @dev Internal helper for unstaking logic.
    function _unstakeAgentInternal(uint256 _agentId, uint256 _amount) internal {
        agentStaking[_agentId].stakedAmount -= _amount;
        totalStakedEVC -= _amount;
        require(evoluCoin.transfer(msg.sender, _amount), "Unstaking: EVC transfer failed");
    }

    /// @notice Claims accrued staking rewards for an agent.
    /// @param _agentId The ID of the agent to claim rewards for.
    function claimStakingRewards(uint256 _agentId) public whenNotPaused nonReentrant {
        require(evoluAgent.ownerOf(_agentId) == msg.sender, "Claim: Not agent owner");
        _claimStakingRewardsInternal(_agentId);
    }

    /// @dev Internal helper to calculate, mint and update last claim time for staking rewards.
    function _claimStakingRewardsInternal(uint256 _agentId) internal {
        require(agentStaking[_agentId].stakedAmount > 0, "Claim: No EVC staked");
        
        uint256 rewardAmount = _getPendingStakingRewards(_agentId);
        
        if (rewardAmount > 0) {
            agentStaking[_agentId].lastRewardClaimTime = block.timestamp; // Reset time after claiming
            // Mint rewards if the protocol holds MINTER_ROLE on EvoluCoin
            evoluCoin.mint(msg.sender, rewardAmount); 
            emit StakingRewardsClaimed(_agentId, msg.sender, rewardAmount);
        }
    }

    /// @notice Calculates pending staking rewards for a given agent.
    /// @param _agentId The ID of the agent.
    /// @return The amount of pending EvoluCoin rewards.
    function _getPendingStakingRewards(uint256 _agentId) internal view returns (uint256) {
        if (agentStaking[_agentId].stakedAmount == 0 || agentStaking[_agentId].lastRewardClaimTime == 0) {
            return 0;
        }

        uint256 timeElapsed = block.timestamp - agentStaking[_agentId].lastRewardClaimTime;
        if (timeElapsed == 0) return 0;

        uint256 rewardRate = protocolParameters[keccak256("STAKING_REWARD_RATE_PER_SECOND")];
        uint256 rateDenominator = protocolParameters[keccak256("STAKING_REWARD_RATE_DENOMINATOR")];
        
        // This calculation is (stakedAmount * rate * timeElapsed) / denominator
        // Using `mulDiv` from SafeMath would be safer, but for 0.8.x standard multiplication/division is usually fine
        // as long as overflows are handled (amounts are reasonable).
        uint256 rewards = (agentStaking[_agentId].stakedAmount * rewardRate * timeElapsed) / rateDenominator;
        return rewards;
    }

    /// @notice Proposes a change to a protocol parameter.
    /// @dev Requires a minimum stake from the proposer and a proposal fee.
    /// @param _paramKey The keccak256 hash of the parameter to change.
    /// @param _newValue The new value for the parameter.
    /// @return The ID of the newly created proposal.
    function proposeParameterChange(bytes32 _paramKey, uint256 _newValue) public whenNotPaused nonReentrant returns (uint256) {
        // Get proposer's total staked EVC across all their agents
        uint256 proposerStakedEVC = 0;
        uint256 numAgents = evoluAgent.balanceOf(msg.sender);
        for(uint i = 0; i < numAgents; i++){
            uint256 agentId = evoluAgent.tokenOfOwnerByIndex(msg.sender, i); // Requires ERC721Enumerable
            proposerStakedEVC += agentStaking[agentId].stakedAmount;
        }
        require(proposerStakedEVC >= protocolParameters[keccak256("GOVERNANCE_MIN_STAKE_TO_PROPOSE")], "Governance: Insufficient personal stake to propose");
        
        // Take proposal fee
        uint256 proposalFee = protocolParameters[keccak256("GOVERNANCE_PROPOSAL_FEE")];
        require(evoluCoin.transferFrom(msg.sender, address(this), proposalFee), "Governance: Proposal fee payment failed");

        _proposalIdCounter.increment();
        uint256 newProposalId = _proposalIdCounter.current();

        uint256 votingPeriod = protocolParameters[keccak256("GOVERNANCE_VOTING_PERIOD")];

        proposals[newProposalId] = Proposal({
            id: newProposalId,
            proposer: msg.sender,
            paramKey: _paramKey,
            newValue: _newValue,
            voteStartTime: block.timestamp,
            voteEndTime: block.timestamp + votingPeriod,
            votesFor: 0,
            votesAgainst: 0,
            status: ProposalStatus.Active
        });

        emit ProposalCreated(newProposalId, _paramKey, _newValue, msg.sender);
        return newProposalId;
    }

    /// @notice Votes on an active proposal.
    /// @dev Voting power is proportional to the caller's total staked EvoluCoin (across all their agents).
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _support True for 'yes', false for 'no'.
    function voteOnProposal(uint256 _proposalId, bool _support) public whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.status == ProposalStatus.Active, "Governance: Proposal not active");
        require(block.timestamp >= proposal.voteStartTime && block.timestamp <= proposal.voteEndTime, "Governance: Voting period not active");
        require(!proposal.hasVoted[msg.sender], "Governance: Already voted on this proposal");

        // Get voter's total staked EVC across all their agents
        uint256 voterStakedEVC = 0;
        uint256 numAgents = evoluAgent.balanceOf(msg.sender);
        for(uint i = 0; i < numAgents; i++){
            uint256 agentId = evoluAgent.tokenOfOwnerByIndex(msg.sender, i); // Requires ERC721Enumerable
            voterStakedEVC += agentStaking[agentId].stakedAmount;
        }

        require(voterStakedEVC > 0, "Governance: No EVC staked to vote");

        if (_support) {
            proposal.votesFor += voterStakedEVC;
        } else {
            proposal.votesAgainst += voterStakedEVC;
        }
        proposal.hasVoted[msg.sender] = true;

        emit VoteCast(_proposalId, msg.sender, _support);
    }

    /// @notice Executes a proposal if it has passed its voting period and met thresholds.
    /// @param _proposalId The ID of the proposal to execute.
    function executeProposal(uint256 _proposalId) public whenNotPaused nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.status == ProposalStatus.Active, "Governance: Proposal not active");
        require(block.timestamp > proposal.voteEndTime, "Governance: Voting period not ended");

        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        require(totalVotes > 0, "Governance: No votes cast");

        uint256 quorumPercentage = protocolParameters[keccak256("GOVERNANCE_QUORUM_PERCENT")];
        uint256 totalStaked = totalStakedEVC; // Current total staked EVC

        // Quorum check: Total votes must be at least X% of total staked EVC
        require(totalVotes * 100 >= totalStaked * quorumPercentage, "Governance: Quorum not reached");
        
        // Majority check: VotesFor must exceed VotesAgainst
        if (proposal.votesFor > proposal.votesAgainst) {
            protocolParameters[proposal.paramKey] = proposal.newValue;
            proposal.status = ProposalStatus.Executed;
            emit ProposalExecuted(_proposalId);
        } else {
            proposal.status = ProposalStatus.Failed;
        }
    }

    // --- Getters / Views ---

    /// @notice Retrieves full details of a specific task.
    /// @param _taskId The ID of the task.
    /// @return A Task struct containing all details.
    function getTask(uint256 _taskId) public view returns (Task memory) {
        return tasks[_taskId];
    }

    /// @notice Returns the amount of EvoluCoin staked to a given agent.
    /// @param _agentId The ID of the agent.
    /// @return The total staked amount.
    function getAgentStakingBalance(uint256 _agentId) public view returns (uint256) {
        return agentStaking[_agentId].stakedAmount;
    }

    /// @notice Returns the address of the EvoluCoin contract.
    function getEvoluCoinAddress() public view returns (address) {
        return address(evoluCoin);
    }

    /// @notice Returns the address of the EvoluAgent contract.
    function getEvoluAgentAddress() public view returns (address) {
        return address(evoluAgent);
    }

    /// @notice Returns the current value of a specific protocol parameter.
    /// @param _paramKey The keccak256 hash of the parameter name.
    /// @return The value of the parameter.
    function getProtocolParameter(bytes32 _paramKey) public view returns (uint256) {
        return protocolParameters[_paramKey];
    }

    /// @notice Returns the total amount of EvoluCoin currently staked across all agents in the protocol.
    function getTotalStakedTokens() public view returns (uint256) {
        return totalStakedEVC;
    }

    /// @notice Returns the current number of tasks.
    function getCurrentTaskId() public view returns (uint256) {
        return _taskIdCounter.current();
    }

    /// @notice Returns the current number of proposals.
    function getCurrentProposalId() public view returns (uint256) {
        return _proposalIdCounter.current();
    }
}
```