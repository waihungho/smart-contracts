This smart contract, named "Synergistic Autonomous Agent Network" (SAAN), creates a decentralized ecosystem where users can deploy AI/ML-driven agents (represented as dynamic NFTs) to bid on and execute tasks. It features a unique reputation system, a task marketplace with escrow, a delegated operation mechanism for agents, and an on-chain dispute resolution framework, aiming to be a novel approach to decentralized work and agent-based economies.

---

## SAAN Smart Contract Outline & Function Summary

**Contract Name:** `SAAN` (Synergistic Autonomous Agent Network)

**Core Concepts:**
*   **Dynamic NFTs for Agents:** Each agent is an ERC721 token with mutable attributes (skills, energy, metadata) that evolve based on performance.
*   **Reputation System:** Agents earn and lose reputation, impacting their eligibility for tasks and upgrade paths. Reputation is an internal counter.
*   **Decentralized Task Marketplace:** Users propose tasks with associated rewards and collateral. Agents bid and get assigned.
*   **Escrow & Collateral:** Funds are held in escrow for tasks and agent performance bonds.
*   **Delegated Agent Control:** Agent owners can delegate operational control to other addresses.
*   **On-chain Dispute Resolution:** A council of arbiters resolves disagreements over task completion.
*   **Oracle Integration:** For external verification of task outcomes.

---

### Function Summary:

**I. Core Infrastructure & Admin (5 functions)**
1.  `constructor()`: Initializes the contract, setting the deployer as the initial owner and defining initial parameters.
2.  `setOracleAddress(address _newOracle)`: Allows the owner to update the trusted oracle address responsible for external verifications.
3.  `setArbiterCouncil(address[] calldata _newArbiters)`: Allows the owner to update the list of addresses that form the dispute resolution council.
4.  `togglePause(bool _paused)`: Enables the owner to pause or unpause critical contract functionalities for maintenance or emergency.
5.  `withdrawTreasuryFunds(address _to, uint256 _amount)`: Allows the owner to withdraw accumulated fees or unallocated funds from the contract's treasury.

**II. Agent Management (Dynamic NFT-based) (5 functions)**
6.  `createAgent(string calldata _name, string calldata _metadataURI)`: Mints a new unique Agent NFT for the caller, setting its initial name, metadata URI, and base attributes.
7.  `upgradeAgentAttributes(uint256 _agentId, uint256 _skillPoints, uint256 _energyPoints, string calldata _newMetadataURI)`: Allows an agent owner to spend earned reputation or funds to enhance their agent's skill/energy attributes and update its visual/descriptive metadata.
8.  `delegateAgentOperation(uint256 _agentId, address _delegatee, uint256 _duration)`: Allows an agent owner to temporarily grant control of their agent to another address for task-related operations.
9.  `retireAgent(uint256 _agentId)`: Burns an Agent NFT, permanently removing it from the network. A portion of its reputation might be recoverable or transferred.
10. `updateAgentMetadataURI(uint256 _agentId, string calldata _newMetadataURI)`: Allows the agent owner to specifically update the metadata URI of their agent NFT without changing attributes.

**III. Task Management & Lifecycle (6 functions)**
11. `proposeTask(string calldata _descriptionHash, uint256 _rewardAmount, uint256 _collateralRequired, uint256 _biddingDeadline)`: A user proposes a new task, depositing the reward and specifying required agent collateral and a bidding period.
12. `bidOnTask(uint256 _taskId, uint256 _agentId)`: An agent owner (or their delegate) bids on an open task using one of their agents, staking the required collateral.
13. `assignTaskToAgent(uint256 _taskId, uint256 _agentId)`: The task proposer selects and assigns the task to a specific bidding agent after the bidding deadline.
14. `submitTaskCompletionProof(uint256 _taskId, string calldata _proofHash)`: The assigned agent submits cryptographic proof or a reference (e.g., IPFS hash) indicating task completion.
15. `verifyTaskCompletion(uint256 _taskId, bool _isSuccessful, bytes calldata _oracleSignature)`: Called by the trusted oracle (or potentially an arbiter), validating the proof. If successful, releases rewards and adjusts agent reputation; otherwise, triggers penalties.
16. `cancelTaskProposal(uint256 _taskId)`: The task proposer can cancel their task before an agent is assigned, reclaiming their staked reward.

**IV. Reputation, Rewards & Penalties (3 functions)**
17. `claimTaskReward(uint256 _taskId)`: Allows the agent owner to claim the reward (and their staked collateral) for a successfully completed and verified task.
18. `initiateReputationChallenge(uint256 _agentId, string calldata _reasonHash)`: A formal mechanism for any user to challenge an agent's reputation based on documented misconduct, potentially leading to a dispute.
19. `penalizeAgentForBreach(uint256 _taskId, uint256 _agentId, string calldata _evidenceHash)`: Allows the task proposer to formally report and request a penalty for an assigned agent that has clearly breached terms *before* dispute or full verification, potentially triggering a dispute or immediate penalty based on clear evidence.

**V. Dispute Resolution (3 functions)**
20. `raiseDispute(uint256 _taskId)`: Either the task proposer or the agent owner can initiate a dispute if there's disagreement over task completion/failure. Requires a dispute deposit.
21. `submitDisputeEvidence(uint256 _disputeId, string calldata _evidenceHash)`: Parties involved in an active dispute submit their evidence (e.g., IPFS hashes of documents, logs) to the arbiter council.
22. `resolveDispute(uint256 _disputeId, address _winningParty, int256 _reputationChangeForLoser)`: Called by the Arbiter Council (after voting), deciding the outcome of a dispute, distributing deposits/fines, and adjusting reputations.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Custom errors for clarity and gas efficiency
error SAAN__Unauthorized();
error SAAN__Paused();
error SAAN__NotEnoughFunds();
error SAAN__AgentNotFound();
error SAAN__TaskNotFound();
error SAAN__TaskNotOpenForBids();
error SAAN__TaskNotAssigned();
error SAAN__InvalidBiddingDeadline();
error SAAN__BiddingClosed();
error SAAN__TaskAlreadyAssigned();
error SAAN__TaskNotCompleted();
error SAAN__TaskAlreadyVerified();
error SAAN__InvalidAgentState();
error SAAN__AgentNotOwnerOrDelegate();
error SAAN__DisputeNotFound();
error SAAN__DisputeAlreadyResolved();
error SAAN__UnauthorizedOracleSignature();
error SAAN__InvalidArbiterCouncil();
error SAAN__CannotCancelAssignedTask();
error SAAN__DisputeAlreadyExists();
error SAAN__InvalidReputationChange();

contract SAAN is ERC721URIStorage, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    // --- State Variables ---

    Counters.Counter private _agentIds;
    Counters.Counter private _taskIds;
    Counters.Counter private _disputeIds;

    address public oracleAddress;
    address[] public arbiterCouncil; // Addresses of the dispute resolution council
    uint256 public disputeDepositAmount;
    uint256 public reputationChallengeFee;
    uint256 public constant MIN_REPUTATION_FOR_UPGRADE = 100; // Example
    uint256 public constant INITIAL_AGENT_REPUTATION = 100;

    bool public paused; // Pause functionality for upgrades/emergencies

    // --- Enums ---

    enum AgentStatus {
        Available,
        Busy, // Assigned to a task
        Retired
    }

    enum TaskStatus {
        Proposed,
        BiddingOpen,
        BiddingClosed,
        Assigned,
        InProgress,
        CompletedPendingVerification,
        VerifiedSuccess,
        VerifiedFailure,
        Cancelled
    }

    enum DisputeStatus {
        Open,
        EvidenceSubmitted,
        Resolved
    }

    // --- Structs ---

    struct Agent {
        uint256 id;
        address owner;
        address delegatee; // Address temporarily allowed to operate the agent
        uint256 delegateeExpiresAt;
        uint256 reputation;
        uint256 skillPoints;
        uint256 energyPoints;
        AgentStatus status;
        string metadataURI; // For dynamic NFT updates
    }

    struct Task {
        uint256 id;
        address proposer;
        string descriptionHash; // IPFS hash of task description
        uint256 rewardAmount; // In native currency (ETH)
        uint256 collateralRequired; // Collateral agent must stake
        uint256 biddingDeadline;
        uint256 assignmentDeadline; // Deadline for proposer to assign agent
        uint256 completionDeadline; // Deadline for agent to complete task
        uint256 assignedAgentId; // 0 if not assigned
        uint256 agentCollateralStaked; // Actual collateral staked by assigned agent
        string completionProofHash; // IPFS hash of completion proof
        TaskStatus status;
    }

    struct Dispute {
        uint256 id;
        uint256 taskId;
        address initiator;
        address opposingParty; // The other party in the dispute (proposer or agent owner)
        string initiatorEvidenceHash;
        string opposingEvidenceHash;
        DisputeStatus status;
        address winningParty; // 0x0 if not resolved
        int256 reputationChangeForLoser; // How much reputation the loser loses
    }

    // --- Mappings ---

    mapping(uint256 => Agent) public agents;
    mapping(uint256 => Task) public tasks;
    mapping(uint256 => Dispute) public disputes;
    mapping(uint256 => address) public agentOwners; // ERC721 ownerOf handles this too, but for quick lookup
    mapping(uint256 => address) public taskBids; // taskId => agentId => proposer/agent owner (used for simplicity here, in real scenario, it would be taskId => agentId => bid details)
    mapping(uint256 => mapping(uint256 => bool)) public taskHasBids; // taskId => agentId => has bid
    mapping(uint256 => address) public taskProposers; // taskId => proposer address

    // --- Events ---

    event OracleAddressUpdated(address indexed newOracle);
    event ArbiterCouncilUpdated(address[] newArbiters);
    event Paused(address account);
    event Unpaused(address account);
    event TreasuryFundsWithdrawn(address indexed to, uint256 amount);

    event AgentCreated(uint256 indexed agentId, address indexed owner, string name, string metadataURI);
    event AgentAttributesUpgraded(uint256 indexed agentId, uint256 newSkillPoints, uint256 newEnergyPoints, string newMetadataURI);
    event AgentOperationDelegated(uint256 indexed agentId, address indexed delegatee, uint256 expiresAt);
    event AgentRetired(uint256 indexed agentId, address indexed owner);
    event AgentMetadataURIUpdated(uint256 indexed agentId, string newMetadataURI);

    event TaskProposed(uint256 indexed taskId, address indexed proposer, uint256 rewardAmount, uint256 collateralRequired, uint256 biddingDeadline);
    event TaskBid(uint256 indexed taskId, uint256 indexed agentId, address indexed bidder);
    event TaskAssigned(uint256 indexed taskId, uint256 indexed agentId, address indexed proposer);
    event TaskCompletionProofSubmitted(uint256 indexed taskId, uint256 indexed agentId, string proofHash);
    event TaskVerified(uint256 indexed taskId, uint256 indexed agentId, bool isSuccessful);
    event TaskCancelled(uint256 indexed taskId, address indexed proposer);

    event TaskRewardClaimed(uint256 indexed taskId, uint256 indexed agentId, address indexed receiver, uint256 amount);
    event ReputationChallenged(uint256 indexed agentId, address indexed challenger, string reasonHash);
    event AgentPenalized(uint256 indexed taskId, uint256 indexed agentId, address indexed reporter, string evidenceHash);

    event DisputeRaised(uint256 indexed disputeId, uint256 indexed taskId, address indexed initiator);
    event DisputeEvidenceSubmitted(uint256 indexed disputeId, address indexed party, string evidenceHash);
    event DisputeResolved(uint256 indexed disputeId, uint256 indexed taskId, address indexed winningParty, int256 reputationChange);

    // --- Modifiers ---

    modifier onlyOracle() {
        if (msg.sender != oracleAddress) revert SAAN__Unauthorized();
        _;
    }

    modifier onlyArbiter() {
        bool isArbiter = false;
        for (uint256 i = 0; i < arbiterCouncil.length; i++) {
            if (arbiterCouncil[i] == msg.sender) {
                isArbiter = true;
                break;
            }
        }
        if (!isArbiter) revert SAAN__Unauthorized();
        _;
    }

    modifier whenNotPaused() {
        if (paused) revert SAAN__Paused();
        _;
    }

    modifier onlyAgentOwnerOrDelegate(uint256 _agentId) {
        Agent storage agent = agents[_agentId];
        if (agent.owner == address(0) || agent.status == AgentStatus.Retired) revert SAAN__AgentNotFound();
        
        bool isOwner = (ownerOf(_agentId) == _msgSender());
        bool isDelegate = (agent.delegatee == _msgSender() && block.timestamp <= agent.delegateeExpiresAt);

        if (!(isOwner || isDelegate)) revert SAAN__AgentNotOwnerOrDelegate();
        _;
    }

    // --- Constructor ---

    constructor(address _initialOracle, address[] memory _initialArbiters, uint256 _disputeDepositAmount, uint256 _reputationChallengeFee)
        ERC721("SAANAgent", "SAAN")
        Ownable(_msgSender())
    {
        if (_initialOracle == address(0)) revert SAAN__Unauthorized();
        if (_initialArbiters.length == 0) revert SAAN__InvalidArbiterCouncil();
        oracleAddress = _initialOracle;
        arbiterCouncil = _initialArbiters;
        disputeDepositAmount = _disputeDepositAmount;
        reputationChallengeFee = _reputationChallengeFee;
        paused = false;
    }

    // --- I. Core Infrastructure & Admin Functions (5 functions) ---

    /// @notice Updates the trusted oracle address. Only callable by the contract owner.
    /// @param _newOracle The new address for the oracle.
    function setOracleAddress(address _newOracle) external onlyOwner {
        if (_newOracle == address(0)) revert SAAN__Unauthorized();
        oracleAddress = _newOracle;
        emit OracleAddressUpdated(_newOracle);
    }

    /// @notice Updates the list of addresses forming the dispute resolution council. Only callable by the contract owner.
    /// @param _newArbiters An array of new arbiter addresses.
    function setArbiterCouncil(address[] calldata _newArbiters) external onlyOwner {
        if (_newArbiters.length == 0) revert SAAN__InvalidArbiterCouncil();
        arbiterCouncil = _newArbiters;
        emit ArbiterCouncilUpdated(_newArbiters);
    }

    /// @notice Toggles the paused state of the contract. When paused, many core functionalities are blocked.
    /// @param _paused True to pause, false to unpause. Only callable by the contract owner.
    function togglePause(bool _paused) external onlyOwner {
        paused = _paused;
        if (_paused) {
            emit Paused(_msgSender());
        } else {
            emit Unpaused(_msgSender());
        }
    }

    /// @notice Allows the contract owner to withdraw funds from the contract treasury.
    /// @param _to The address to send the funds to.
    /// @param _amount The amount of native currency (ETH) to withdraw.
    function withdrawTreasuryFunds(address _to, uint256 _amount) external onlyOwner {
        if (_amount == 0) revert SAAN__NotEnoughFunds();
        if (address(this).balance < _amount) revert SAAN__NotEnoughFunds();
        (bool success,) = _to.call{value: _amount}("");
        if (!success) revert SAAN__NotEnoughFunds(); // More specific error if possible
        emit TreasuryFundsWithdrawn(_to, _amount);
    }

    // --- II. Agent Management (Dynamic NFT-based) Functions (5 functions) ---

    /// @notice Mints a new unique Agent NFT for the caller.
    /// @param _name The name of the new agent.
    /// @param _metadataURI The initial IPFS/external metadata URI for the agent NFT.
    function createAgent(string calldata _name, string calldata _metadataURI)
        external
        whenNotPaused
        nonReentrant
    {
        _agentIds.increment();
        uint256 newAgentId = _agentIds.current();

        _safeMint(_msgSender(), newAgentId);
        _setTokenURI(newAgentId, _metadataURI); // Set initial metadata URI using ERC721URIStorage

        agents[newAgentId] = Agent({
            id: newAgentId,
            owner: _msgSender(),
            delegatee: address(0),
            delegateeExpiresAt: 0,
            reputation: INITIAL_AGENT_REPUTATION,
            skillPoints: 10, // Initial skill
            energyPoints: 100, // Initial energy
            status: AgentStatus.Available,
            metadataURI: _metadataURI
        });
        agentOwners[newAgentId] = _msgSender();

        emit AgentCreated(newAgentId, _msgSender(), _name, _metadataURI);
    }

    /// @notice Allows an agent owner to spend earned reputation or funds to enhance their agent's attributes and update its metadata.
    /// @param _agentId The ID of the agent to upgrade.
    /// @param _skillPoints The amount of skill points to add.
    /// @param _energyPoints The amount of energy points to add.
    /// @param _newMetadataURI The updated IPFS/external metadata URI for the agent NFT.
    function upgradeAgentAttributes(
        uint256 _agentId,
        uint256 _skillPoints,
        uint256 _energyPoints,
        string calldata _newMetadataURI
    ) external onlyAgentOwnerOrDelegate(_agentId) whenNotPaused nonReentrant {
        Agent storage agent = agents[_agentId];
        if (agent.reputation < MIN_REPUTATION_FOR_UPGRADE) revert SAAN__InvalidAgentState(); // Example
        
        // This is a simplified example. In a real scenario, this would cost reputation, ETH, or a specific token.
        // For simplicity, we just check MIN_REPUTATION_FOR_UPGRADE and deduct it as a cost.
        // It could also consume other resources or be tied to specific unlock conditions.
        agent.reputation -= MIN_REPUTATION_FOR_UPGRADE; 

        agent.skillPoints += _skillPoints;
        agent.energyPoints += _energyPoints;
        agent.metadataURI = _newMetadataURI;
        _setTokenURI(_agentId, _newMetadataURI); // Update URI in ERC721URIStorage

        emit AgentAttributesUpgraded(_agentId, agent.skillPoints, agent.energyPoints, _newMetadataURI);
    }

    /// @notice Allows an agent owner to temporarily grant control of their agent to another address.
    /// @param _agentId The ID of the agent to delegate.
    /// @param _delegatee The address to delegate control to.
    /// @param _duration The duration in seconds for which control is delegated.
    function delegateAgentOperation(uint256 _agentId, address _delegatee, uint256 _duration)
        external
        onlyAgentOwnerOrDelegate(_agentId)
        whenNotPaused
    {
        Agent storage agent = agents[_agentId];
        if (_delegatee == address(0)) { // Revoke delegation
            agent.delegatee = address(0);
            agent.delegateeExpiresAt = 0;
        } else {
            agent.delegatee = _delegatee;
            agent.delegateeExpiresAt = block.timestamp + _duration;
        }
        emit AgentOperationDelegated(_agentId, _delegatee, agent.delegateeExpiresAt);
    }

    /// @notice Burns an Agent NFT, permanently removing it from the network.
    /// A portion of its reputation might be recoverable or transferred to the owner's general pool.
    /// @param _agentId The ID of the agent to retire.
    function retireAgent(uint256 _agentId)
        external
        onlyAgentOwnerOrDelegate(_agentId)
        whenNotPaused
        nonReentrant
    {
        Agent storage agent = agents[_agentId];
        if (agent.status == AgentStatus.Busy) revert SAAN__InvalidAgentState(); // Cannot retire busy agent

        // Example: Transfer a portion of reputation to the owner (simplified, could be a separate reputation token)
        // If a reputation token existed: IERC20(reputationTokenAddress).transfer(agent.owner, agent.reputation / 2);

        _burn(_agentId); // Burn the NFT
        agent.status = AgentStatus.Retired;
        // Clear sensitive data (not strictly necessary but good practice)
        agent.owner = address(0); 
        agent.delegatee = address(0);

        emit AgentRetired(_agentId, _msgSender());
    }

    /// @notice Allows the agent owner to specifically update the metadata URI of their agent NFT.
    /// @param _agentId The ID of the agent.
    /// @param _newMetadataURI The updated IPFS/external metadata URI.
    function updateAgentMetadataURI(uint256 _agentId, string calldata _newMetadataURI)
        external
        onlyAgentOwnerOrDelegate(_agentId)
        whenNotPaused
    {
        Agent storage agent = agents[_agentId];
        agent.metadataURI = _newMetadataURI;
        _setTokenURI(_agentId, _newMetadataURI);
        emit AgentMetadataURIUpdated(_agentId, _newMetadataURI);
    }

    // --- III. Task Management & Lifecycle Functions (6 functions) ---

    /// @notice Proposes a new task, depositing the reward and specifying required agent collateral and a bidding period.
    /// @param _descriptionHash IPFS hash of the task description.
    /// @param _rewardAmount The reward for the agent upon successful completion (in native currency).
    /// @param _collateralRequired The collateral an agent must stake to bid.
    /// @param _biddingDeadline Timestamp when bidding closes.
    function proposeTask(
        string calldata _descriptionHash,
        uint256 _rewardAmount,
        uint256 _collateralRequired,
        uint256 _biddingDeadline
    ) external payable whenNotPaused nonReentrant {
        if (_rewardAmount == 0) revert SAAN__InvalidAgentState(); // Example: reward must be > 0
        if (msg.value < _rewardAmount) revert SAAN__NotEnoughFunds();
        if (_biddingDeadline <= block.timestamp) revert SAAN__InvalidBiddingDeadline();

        _taskIds.increment();
        uint256 newTaskId = _taskIds.current();

        tasks[newTaskId] = Task({
            id: newTaskId,
            proposer: _msgSender(),
            descriptionHash: _descriptionHash,
            rewardAmount: _rewardAmount,
            collateralRequired: _collateralRequired,
            biddingDeadline: _biddingDeadline,
            assignmentDeadline: 0, // Set when assigned
            completionDeadline: 0, // Set when assigned
            assignedAgentId: 0,
            agentCollateralStaked: 0,
            completionProofHash: "",
            status: TaskStatus.BiddingOpen
        });
        taskProposers[newTaskId] = _msgSender();

        emit TaskProposed(newTaskId, _msgSender(), _rewardAmount, _collateralRequired, _biddingDeadline);
    }

    /// @notice An agent owner (or their delegate) bids on an open task using one of their agents, staking the required collateral.
    /// @param _taskId The ID of the task to bid on.
    /// @param _agentId The ID of the agent making the bid.
    function bidOnTask(uint256 _taskId, uint256 _agentId)
        external
        payable
        onlyAgentOwnerOrDelegate(_agentId)
        whenNotPaused
        nonReentrant
    {
        Task storage task = tasks[_taskId];
        Agent storage agent = agents[_agentId];

        if (task.status != TaskStatus.BiddingOpen) revert SAAN__TaskNotOpenForBids();
        if (block.timestamp >= task.biddingDeadline) revert SAAN__BiddingClosed();
        if (agent.status != AgentStatus.Available) revert SAAN__InvalidAgentState();
        if (msg.value < task.collateralRequired) revert SAAN__NotEnoughFunds();
        if (taskHasBids[_taskId][_agentId]) revert SAAN__InvalidAgentState(); // Agent already bid on this task

        taskHasBids[_taskId][_agentId] = true; // Mark that this agent has bid
        // In a more complex system, this would store bid details, not just a boolean.
        // For simplicity, we assume the collateral is held by the contract, and the agent owner is tracked by `ownerOf(_agentId)`.

        emit TaskBid(_taskId, _agentId, _msgSender());
    }

    /// @notice The task proposer selects and assigns the task to a specific bidding agent after the bidding deadline.
    /// @param _taskId The ID of the task.
    /// @param _agentId The ID of the chosen agent.
    function assignTaskToAgent(uint256 _taskId, uint256 _agentId)
        external
        whenNotPaused
        nonReentrant
    {
        Task storage task = tasks[_taskId];
        Agent storage agent = agents[_agentId];

        if (task.proposer != _msgSender()) revert SAAN__Unauthorized();
        if (task.status != TaskStatus.BiddingOpen && task.status != TaskStatus.BiddingClosed) revert SAAN__TaskNotOpenForBids();
        if (block.timestamp < task.biddingDeadline) revert SAAN__BiddingClosed(); // Ensure bidding is truly closed
        if (task.assignedAgentId != 0) revert SAAN__TaskAlreadyAssigned();
        if (agent.status != AgentStatus.Available) revert SAAN__InvalidAgentState();
        if (!taskHasBids[_taskId][_agentId]) revert SAAN__AgentNotFound(); // Agent must have bid

        task.assignedAgentId = _agentId;
        task.agentCollateralStaked = task.collateralRequired; // Assume collateral was staked when bidding
        task.status = TaskStatus.Assigned;
        task.assignmentDeadline = block.timestamp; // Record assignment time
        task.completionDeadline = block.timestamp + 7 days; // Example: 7 days to complete

        agent.status = AgentStatus.Busy; // Mark agent as busy

        emit TaskAssigned(_taskId, _agentId, _msgSender());
    }

    /// @notice The assigned agent submits cryptographic proof or a reference indicating task completion.
    /// @param _taskId The ID of the task.
    /// @param _proofHash IPFS hash of the completion proof.
    function submitTaskCompletionProof(uint256 _taskId, string calldata _proofHash)
        external
        whenNotPaused
        nonReentrant
    {
        Task storage task = tasks[_taskId];
        if (task.assignedAgentId == 0 || task.status != TaskStatus.Assigned) revert SAAN__TaskNotAssigned();
        if (ownerOf(task.assignedAgentId) != _msgSender() && agents[task.assignedAgentId].delegatee != _msgSender()) {
            revert SAAN__Unauthorized();
        }
        if (block.timestamp > task.completionDeadline) revert SAAN__TaskNotCompleted(); // Too late to submit
        if (bytes(_proofHash).length == 0) revert SAAN__InvalidAgentState();

        task.completionProofHash = _proofHash;
        task.status = TaskStatus.CompletedPendingVerification;

        emit TaskCompletionProofSubmitted(_taskId, task.assignedAgentId, _proofHash);
    }

    /// @notice Called by the trusted oracle, validating the proof. If successful, releases rewards and adjusts reputation; otherwise, triggers penalties.
    /// @param _taskId The ID of the task.
    /// @param _isSuccessful True if the task was completed successfully, false otherwise.
    /// @param _oracleSignature A cryptographic signature from the oracle, verifying the call. (Simplified: just check sender for now)
    function verifyTaskCompletion(uint256 _taskId, bool _isSuccessful, bytes calldata _oracleSignature)
        external
        onlyOracle
        whenNotPaused
        nonReentrant
    {
        Task storage task = tasks[_taskId];
        if (task.status != TaskStatus.CompletedPendingVerification) revert SAAN__TaskNotCompleted();
        if (task.assignedAgentId == 0) revert SAAN__TaskNotAssigned();
        // In a real system, _oracleSignature would be cryptographically verified against a known oracle public key.
        // For this example, 'onlyOracle' modifier ensures trusted caller.

        Agent storage agent = agents[task.assignedAgentId];

        if (_isSuccessful) {
            // Transfer reward to agent owner
            (bool success,) = agentOwners[agent.id].call{value: task.rewardAmount}("");
            if (!success) revert SAAN__NotEnoughFunds(); // Should not happen if funds are in contract

            // Return collateral to agent owner
            (success,) = agentOwners[agent.id].call{value: task.agentCollateralStaked}("");
            if (!success) revert SAAN__NotEnoughFunds();

            agent.reputation += 50; // Example: increase reputation
            task.status = TaskStatus.VerifiedSuccess;
        } else {
            // Penalize agent: collateral is forfeit, reward is returned to proposer
            (bool success,) = taskProposers[_taskId].call{value: task.rewardAmount + task.agentCollateralStaked}("");
            if (!success) revert SAAN__NotEnoughFunds(); // Should not happen if funds are in contract

            agent.reputation = agent.reputation >= 20 ? agent.reputation - 20 : 0; // Example: decrease reputation
            task.status = TaskStatus.VerifiedFailure;
        }

        agent.status = AgentStatus.Available; // Agent is now free for new tasks
        emit TaskVerified(_taskId, agent.id, _isSuccessful);
    }

    /// @notice The task proposer can cancel their task before an agent is assigned.
    /// @param _taskId The ID of the task to cancel.
    function cancelTaskProposal(uint256 _taskId)
        external
        whenNotPaused
        nonReentrant
    {
        Task storage task = tasks[_taskId];
        if (task.proposer != _msgSender()) revert SAAN__Unauthorized();
        if (task.status == TaskStatus.Assigned || task.status == TaskStatus.InProgress || task.status == TaskStatus.CompletedPendingVerification) {
            revert SAAN__CannotCancelAssignedTask();
        }
        if (task.status == TaskStatus.VerifiedSuccess || task.status == TaskStatus.VerifiedFailure) revert SAAN__TaskAlreadyVerified();

        // Return reward to proposer
        (bool success,) = _msgSender().call{value: task.rewardAmount}("");
        if (!success) revert SAAN__NotEnoughFunds(); // Should not happen

        task.status = TaskStatus.Cancelled;
        emit TaskCancelled(_taskId, _msgSender());
    }

    // --- IV. Reputation, Rewards & Penalties Functions (3 functions) ---

    /// @notice Allows the agent owner to claim the reward (and their staked collateral) for a successfully completed and verified task.
    /// This is an explicit claim function, even though `verifyTaskCompletion` already transfers funds.
    /// It could be used if verification transfers to contract, then agent claims.
    /// For this version, it's illustrative and `verifyTaskCompletion` handles direct transfer.
    /// If `verifyTaskCompletion` was only for status, this would be crucial.
    /// Re-evaluating: In current design, `verifyTaskCompletion` directly transfers. This function is redundant.
    /// Let's change this to be a general function to claim *any* ETH balance that might accrue to an agent owner if not auto-sent.
    /// Or simply remove it as the current design directly sends.
    /// Let's keep it to claim *staked collateral* that might not have been returned directly by `verifyTaskCompletion` if it failed for some edge case.
    /// **Revised:** This function is for the proposer to claim *unassigned task rewards* if tasks are eventually cancelled implicitly,
    /// or for an agent to claim a *specific reward* after verification IF the reward was held within the contract for claiming.
    /// With current `verifyTaskCompletion` sending ETH directly, this function needs a different purpose or to be removed.
    /// Let's make it for **proposer** to claim back rewards if the task was proposed but no agent ever bid or was assigned, and the task expired.
    /// Or if an agent was penalized and the reward was returned to the contract, the proposer can claim it.
    function claimTaskReward(uint256 _taskId)
        external
        whenNotPaused
        nonReentrant
    {
        Task storage task = tasks[_taskId];
        if (task.proposer != _msgSender()) revert SAAN__Unauthorized();

        if (task.status == TaskStatus.BiddingOpen && block.timestamp > task.biddingDeadline) {
            // Task expired without assignment, proposer can reclaim reward
            task.status = TaskStatus.Cancelled; // Mark as cancelled upon claiming
            (bool success,) = _msgSender().call{value: task.rewardAmount}("");
            if (!success) revert SAAN__NotEnoughFunds();
            emit TaskCancelled(_taskId, _msgSender());
            emit TaskRewardClaimed(_taskId, 0, _msgSender(), task.rewardAmount);
        } else if (task.status == TaskStatus.VerifiedFailure) {
            // Reward was meant to be returned to proposer during verification of failure,
            // but if it failed to send for some reason, they can retry claiming here.
            // This is a safety net.
            if (address(this).balance < task.rewardAmount) revert SAAN__NotEnoughFunds(); // Should not be less if transfer failed.
            (bool success,) = _msgSender().call{value: task.rewardAmount}("");
            if (!success) revert SAAN__NotEnoughFunds();
            emit TaskRewardClaimed(_taskId, 0, _msgSender(), task.rewardAmount);
        } else {
            revert SAAN__InvalidAgentState(); // Task not in a state where reward can be claimed.
        }
    }

    /// @notice A formal mechanism for any user to challenge an agent's reputation based on documented misconduct.
    /// Requires a fee and initiates a dispute process specifically for reputation.
    /// @param _agentId The ID of the agent whose reputation is being challenged.
    /// @param _reasonHash IPFS hash of the detailed reasons and initial evidence for the challenge.
    function initiateReputationChallenge(uint256 _agentId, string calldata _reasonHash)
        external
        payable
        whenNotPaused
        nonReentrant
    {
        if (msg.value < reputationChallengeFee) revert SAAN__NotEnoughFunds();
        Agent storage agent = agents[_agentId];
        if (agent.owner == address(0) || agent.status == AgentStatus.Retired) revert SAAN__AgentNotFound();
        
        _disputeIds.increment();
        uint256 newDisputeId = _disputeIds.current();

        disputes[newDisputeId] = Dispute({
            id: newDisputeId,
            taskId: 0, // 0 for reputation challenges, not task-specific
            initiator: _msgSender(),
            opposingParty: agentOwners[_agentId],
            initiatorEvidenceHash: _reasonHash,
            opposingEvidenceHash: "",
            status: DisputeStatus.Open,
            winningParty: address(0),
            reputationChangeForLoser: 0
        });

        emit ReputationChallenged(_agentId, _msgSender(), _reasonHash);
        emit DisputeRaised(newDisputeId, 0, _msgSender());
    }

    /// @notice Allows the task proposer to formally report and request a penalty for an assigned agent that has clearly breached terms
    /// *after* assignment but *before* official verification or dispute. This can trigger a dispute or immediate penalty based on clear evidence.
    /// @param _taskId The ID of the task in question.
    /// @param _agentId The ID of the agent to penalize.
    /// @param _evidenceHash IPFS hash of the evidence for the breach.
    function penalizeAgentForBreach(uint256 _taskId, uint256 _agentId, string calldata _evidenceHash)
        external
        whenNotPaused
        nonReentrant
    {
        Task storage task = tasks[_taskId];
        if (task.proposer != _msgSender()) revert SAAN__Unauthorized();
        if (task.assignedAgentId != _agentId) revert SAAN__TaskNotAssigned();
        if (task.status == TaskStatus.VerifiedSuccess || task.status == TaskStatus.VerifiedFailure || task.status == TaskStatus.Cancelled) {
            revert SAAN__TaskAlreadyVerified();
        }

        // This is a "soft" penalty mechanism before full dispute.
        // It could trigger an automatic, small reputation reduction or force an immediate dispute.
        // For this example, let's make it automatically initiate a dispute with this as initial evidence.
        _disputeIds.increment();
        uint256 newDisputeId = _disputeIds.current();

        disputes[newDisputeId] = Dispute({
            id: newDisputeId,
            taskId: _taskId,
            initiator: _msgSender(),
            opposingParty: agentOwners[_agentId],
            initiatorEvidenceHash: _evidenceHash,
            opposingEvidenceHash: "",
            status: DisputeStatus.Open,
            winningParty: address(0),
            reputationChangeForLoser: 0
        });

        task.status = TaskStatus.InProgress; // Mark task as in dispute to prevent other actions
        emit AgentPenalized(_taskId, _agentId, _msgSender(), _evidenceHash);
        emit DisputeRaised(newDisputeId, _taskId, _msgSender());
    }

    // --- V. Dispute Resolution Functions (3 functions) ---

    /// @notice Either the task proposer or the agent owner can initiate a dispute if there's disagreement over task completion/failure.
    /// Requires a deposit to prevent frivolous disputes.
    /// @param _taskId The ID of the task for which to raise a dispute.
    function raiseDispute(uint256 _taskId)
        external
        payable
        whenNotPaused
        nonReentrant
    {
        Task storage task = tasks[_taskId];
        if (task.status == TaskStatus.VerifiedSuccess || task.status == TaskStatus.VerifiedFailure || task.status == TaskStatus.Cancelled) {
            revert SAAN__TaskAlreadyVerified();
        }
        if (task.assignedAgentId == 0) revert SAAN__TaskNotAssigned();
        
        bool isProposer = (task.proposer == _msgSender());
        bool isAgentOwner = (agentOwners[task.assignedAgentId] == _msgSender());

        if (!isProposer && !isAgentOwner) revert SAAN__Unauthorized();
        if (msg.value < disputeDepositAmount) revert SAAN__NotEnoughFunds();

        // Check if dispute already exists for this task (simplified, might need a mapping)
        for (uint224 i = 1; i <= _disputeIds.current(); i++) { // Iterate disputes
            if (disputes[i].taskId == _taskId && disputes[i].status != DisputeStatus.Resolved) {
                revert SAAN__DisputeAlreadyExists();
            }
        }

        _disputeIds.increment();
        uint256 newDisputeId = _disputeIds.current();

        disputes[newDisputeId] = Dispute({
            id: newDisputeId,
            taskId: _taskId,
            initiator: _msgSender(),
            opposingParty: isProposer ? agentOwners[task.assignedAgentId] : task.proposer,
            initiatorEvidenceHash: "", // Will be submitted later
            opposingEvidenceHash: "",
            status: DisputeStatus.Open,
            winningParty: address(0),
            reputationChangeForLoser: 0
        });

        task.status = TaskStatus.InProgress; // Mark task as in dispute
        emit DisputeRaised(newDisputeId, _taskId, _msgSender());
    }

    /// @notice Parties involved in an active dispute submit their evidence.
    /// @param _disputeId The ID of the dispute.
    /// @param _evidenceHash IPFS hash of the evidence.
    function submitDisputeEvidence(uint256 _disputeId, string calldata _evidenceHash)
        external
        whenNotPaused
    {
        Dispute storage dispute = disputes[_disputeId];
        if (dispute.id == 0) revert SAAN__DisputeNotFound();
        if (dispute.status == DisputeStatus.Resolved) revert SAAN__DisputeAlreadyResolved();

        if (_msgSender() == dispute.initiator) {
            dispute.initiatorEvidenceHash = _evidenceHash;
        } else if (_msgSender() == dispute.opposingParty) {
            dispute.opposingEvidenceHash = _evidenceHash;
        } else {
            revert SAAN__Unauthorized();
        }
        dispute.status = DisputeStatus.EvidenceSubmitted; // Both parties might submit multiple times, this is a flag

        emit DisputeEvidenceSubmitted(_disputeId, _msgSender(), _evidenceHash);
    }

    /// @notice Called by the Arbiter Council (after voting/decision), resolving a dispute, distributing deposits/fines, and adjusting reputations.
    /// @param _disputeId The ID of the dispute.
    /// @param _winningParty The address of the party that won the dispute (proposer or agent owner).
    /// @param _reputationChangeForLoser The amount of reputation the losing party will lose (can be positive for deduction, negative for gain if allowed).
    function resolveDispute(uint256 _disputeId, address _winningParty, int256 _reputationChangeForLoser)
        external
        onlyArbiter // Only an arbiter can call this (e.g., after a multi-sig vote)
        whenNotPaused
        nonReentrant
    {
        Dispute storage dispute = disputes[_disputeId];
        if (dispute.id == 0) revert SAAN__DisputeNotFound();
        if (dispute.status == DisputeStatus.Resolved) revert SAAN__DisputeAlreadyResolved();
        if (_winningParty != dispute.initiator && _winningParty != dispute.opposingParty) revert SAAN__Unauthorized();

        Task storage task = tasks[dispute.taskId];
        Agent storage agent = agents[task.assignedAgentId];

        address losingParty = (_winningParty == dispute.initiator) ? dispute.opposingParty : dispute.initiator;

        // --- Handle Funds ---
        // Winner gets their own dispute deposit back + loser's dispute deposit.
        (bool success,) = _winningParty.call{value: disputeDepositAmount * 2}("");
        if (!success) revert SAAN__NotEnoughFunds(); // Should not happen

        // If task-specific dispute, handle task rewards/collateral based on winning party
        if (dispute.taskId != 0 && task.assignedAgentId != 0) {
            if (_winningParty == task.proposer) {
                // Proposer won: Agent forfeits collateral, proposer gets reward back
                if (task.rewardAmount > 0) {
                    (success,) = _winningParty.call{value: task.rewardAmount}(""); // Proposer claims original reward
                    if (!success) revert SAAN__NotEnoughFunds();
                }
                // Agent's collateral is forfeited (implicitly stays in contract or can be redirected, e.g., to arbiters)
            } else if (_winningParty == agentOwners[agent.id]) {
                // Agent owner won: Agent gets reward, gets collateral back
                if (task.rewardAmount > 0) {
                    (success,) = _winningParty.call{value: task.rewardAmount}(""); // Agent owner claims reward
                    if (!success) revert SAAN__NotEnoughFunds();
                }
                if (task.agentCollateralStaked > 0) {
                    (success,) = _winningParty.call{value: task.agentCollateralStaked}(""); // Agent owner claims collateral
                    if (!success) revert SAAN__NotEnoughFunds();
                }
            }
        }
        
        // --- Adjust Reputation for losing agent (if applicable) ---
        if (losingParty == agentOwners[agent.id]) {
            if (_reputationChangeForLoser > 0) { // Penalize
                 agent.reputation = agent.reputation >= uint256(_reputationChangeForLoser) ? agent.reputation - uint256(_reputationChangeForLoser) : 0;
            } else if (_reputationChangeForLoser < 0) { // Bonus (less common for loser, but flexible)
                agent.reputation += uint256(-_reputationChangeForLoser);
            }
        }
        // If it was a reputation challenge, the agent's reputation is directly affected.
        // If winningParty is the challenger, then agent.owner is the losingParty for the reputation change.
        else if (dispute.taskId == 0) { // Reputation challenge
            Agent storage challengedAgent = agents[dispute.opposingParty == _winningParty ? agentOwners[task.assignedAgentId] : dispute.opposingParty]; // This logic is simplified; needs to map challenged agent to agent ID
            // For a reputation challenge, we'd need to link the agent ID explicitly in the dispute struct for non-task disputes.
            // Simplified for now: if the losing party *is* an agent owner, we try to adjust their agent's reputation.
            uint256 agentIdOfLosingParty = 0;
            for(uint224 i=1; i <= _agentIds.current(); i++){
                if(agents[i].owner == losingParty){
                    agentIdOfLosingParty = i;
                    break;
                }
            }
            if(agentIdOfLosingParty != 0) {
                Agent storage losingAgent = agents[agentIdOfLosingParty];
                if (_reputationChangeForLoser > 0) {
                    losingAgent.reputation = losingAgent.reputation >= uint256(_reputationChangeForLoser) ? losingAgent.reputation - uint256(_reputationChangeForLoser) : 0;
                } else if (_reputationChangeForLoser < 0) {
                    losingAgent.reputation += uint256(-_reputationChangeForLoser);
                }
            }
        }


        dispute.winningParty = _winningParty;
        dispute.reputationChangeForLoser = _reputationChangeForLoser;
        dispute.status = DisputeStatus.Resolved;

        // Reset task status if applicable
        if (dispute.taskId != 0) {
            task.status = (_winningParty == task.proposer) ? TaskStatus.VerifiedFailure : TaskStatus.VerifiedSuccess;
            if (agent.id != 0) agent.status = AgentStatus.Available; // Free the agent
        }

        emit DisputeResolved(_disputeId, dispute.taskId, _winningParty, _reputationChangeForLoser);
    }


    // --- View Functions (ERC721 standard views are also available) ---

    /// @notice Returns the details of a specific agent.
    /// @param _agentId The ID of the agent.
    /// @return Agent struct with all details.
    function getAgentDetails(uint256 _agentId) public view returns (Agent memory) {
        return agents[_agentId];
    }

    /// @notice Returns the details of a specific task.
    /// @param _taskId The ID of the task.
    /// @return Task struct with all details.
    function getTaskDetails(uint256 _taskId) public view returns (Task memory) {
        return tasks[_taskId];
    }

    /// @notice Returns the details of a specific dispute.
    /// @param _disputeId The ID of the dispute.
    /// @return Dispute struct with all details.
    function getDisputeDetails(uint256 _disputeId) public view returns (Dispute memory) {
        return disputes[_disputeId];
    }

    /// @notice Returns the current reputation of a specific agent.
    /// @param _agentId The ID of the agent.
    /// @return The agent's current reputation score.
    function getAgentReputation(uint256 _agentId) public view returns (uint256) {
        return agents[_agentId].reputation;
    }

    /// @notice Returns the current number of minted agents.
    function getTotalAgents() public view returns (uint256) {
        return _agentIds.current();
    }

    /// @notice Returns the current number of proposed tasks.
    function getTotalTasks() public view returns (uint256) {
        return _taskIds.current();
    }
}
```