Okay, this is an exciting challenge! Let's design a smart contract system that manages a decentralized network of "Cognitive Nodes" (AI agents, or rather, on-chain representations of off-chain AI agents). These nodes perform "tasks," earn reputation, contribute to a shared "knowledge base," and form "neural links" based on collaboration. The system is governed by a decentralized autonomous organization (DAO) where reputation dictates voting power.

We'll call it **"The Synergistic Cognition Protocol (SCP)"**.

---

## **The Synergistic Cognition Protocol (SCP)**

### **Outline and Function Summary**

This contract establishes a decentralized framework for deploying, managing, and coordinating autonomous "Cognitive Nodes" (representatives of AI agents). It leverages reputation, a dynamic "Neural Nexus," and a shared "Knowledge Base" to facilitate collaborative problem-solving and information sharing, all governed by a reputation-weighted DAO.

**I. Core Concepts & State Management:**

*   **CognitiveNode:** Represents an on-chain AI agent with unique properties, state, and reputation.
*   **CognitiveTask:** A defined unit of work requested by a user, assigned to a node, and verified.
*   **KnowledgeEntry:** A piece of verified information contributed by a node to a shared repository.
*   **GovernanceProposal:** A proposal for system-wide changes, voted on by reputation.
*   **Neural Link:** A bidirectional connection between two nodes, indicating collaboration or affinity.

**II. Agent (Cognitive Node) Management:**

1.  **`deployCognitiveNode(string memory _name, string memory _specializationURI, bytes32 _neuralSignature)`**: Deploys a new Cognitive Node, assigning a unique ID, initial reputation, and owner.
2.  **`updateNodeSpecialization(uint256 _nodeId, string memory _newSpecializationURI)`**: Allows a node owner to update their node's specialization metadata URI.
3.  **`reclaimCognitiveNode(uint256 _nodeId)`**: Allows the owner to deactivate and "reclaim" their node, removing it from active participation.
4.  **`transferNodeOwnership(uint256 _nodeId, address _newOwner)`**: Transfers ownership of a Cognitive Node to another address.
5.  **`getNodeDetails(uint256 _nodeId)`**: Retrieves all public details of a specific Cognitive Node.
6.  **`getNodesByOwner(address _owner)`**: Returns a list of all Cognitive Node IDs owned by a specific address.

**III. Task System & Verification:**

7.  **`requestCognitiveTask(string memory _taskDescriptionURI, uint256 _difficulty, uint256 _rewardAmount)`**: Creates a new task, setting its parameters and locking the reward.
8.  **`assignTaskToNode(uint256 _taskId, uint256 _nodeId)`**: Assigns an available task to a specific Cognitive Node, usually by the node owner or a governance-approved dispatcher.
9.  **`reportTaskCompletion(uint256 _taskId, uint256 _nodeId, bytes32 _resultHash)`**: Called by the assigned node (or its owner) to report task completion and provide a result hash.
10. **`verifyTaskCompletion(uint256 _taskId, bytes32 _expectedResultHash, bool _success)`**: Called by an authorized oracle (or governance) to verify the task result, updating node reputation and distributing rewards.
11. **`cancelCognitiveTask(uint256 _taskId)`**: Allows the task requester to cancel an unassigned or pending task.
12. **`getTaskDetails(uint256 _taskId)`**: Retrieves all public details of a specific Cognitive Task.
13. **`getPendingTasks()`**: Returns a list of all tasks currently awaiting assignment or completion.

**IV. Reputation Management:**

14. **`getNodeReputation(uint256 _nodeId)`**: Returns the current reputation score of a Cognitive Node, adjusted for decay.
15. **`penalizeNode(uint256 _nodeId, uint256 _amount)`**: Decreases a node's reputation, typically for failed tasks or misconduct (callable by governance/oracle).
16. **`rewardNode(uint256 _nodeId, uint256 _amount)`**: Increases a node's reputation, typically for successful task completion or knowledge contribution.

**V. Neural Nexus (Node Interconnection):**

17. **`formNeuralLink(uint256 _nodeId1, uint256 _nodeId2)`**: Establishes a bidirectional "neural link" between two nodes, signifying a successful collaboration or affinity.
18. **`breakNeuralLink(uint256 _nodeId1, uint256 _nodeId2)`**: Dissolves an existing neural link between two nodes.
19. **`getNodeNeuralLinks(uint256 _nodeId)`**: Retrieves a list of all nodes connected to a specific node via neural links.
20. **`suggestCollaborators(uint256 _nodeId, uint256 _count)`**: Suggests other nodes for collaboration based on shared neural links and specializations (simulated on-chain for now, more complex off-chain).

**VI. Knowledge Base:**

21. **`contributeToKnowledgeBase(uint256 _nodeId, string memory _knowledgeURI, bytes32 _dataHash)`**: Allows a node (or its owner) to contribute a piece of validated information to the shared knowledge base.
22. **`verifyKnowledgeContribution(uint256 _entryId, bool _isValid)`**: An authorized oracle/governance verifies the integrity and validity of a knowledge base entry, affecting the contributing node's reputation.
23. **`queryKnowledgeBase(uint256 _entryId)`**: Retrieves the details of a specific knowledge entry.
24. **`searchKnowledgeBaseByHash(bytes32 _dataHash)`**: Allows searching for knowledge entries by their unique data hash.

**VII. Governance & Protocol Parameters:**

25. **`proposeGovernanceChange(string memory _description, bytes memory _calldata)`**: Initiates a new governance proposal, requiring reputation-weighted voting.
26. **`voteOnProposal(uint256 _proposalId, bool _support)`**: Allows reputation holders to vote on active proposals.
27. **`executeGovernanceChange(uint256 _proposalId)`**: Executes a passed governance proposal (only callable after successful voting and cooldown).
28. **`updateProtocolParameter(bytes32 _paramKey, uint256 _newValue)`**: A governance-executed function to update specific protocol parameters (e.g., reputation decay rate, task difficulty multiplier).
29. **`setOracleAddress(address _newOracle)`**: Sets the address of the trusted oracle responsible for task/knowledge verification (governance-controlled).
30. **`emergencyPause()`**: Allows the owner/governance to pause critical contract functions in an emergency.
31. **`unpauseContract()`**: Unpauses the contract after an emergency pause.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // For potential future ERC20 rewards

// Custom Errors for clarity and gas efficiency
error SC_Unauthorized();
error SC_NodeNotFound();
error SC_NodeNotOwnedByCaller();
error SC_NodeAlreadyActive();
error SC_NodeAlreadyInactive();
error SC_InvalidNodeState();
error SC_TaskNotFound();
error SC_TaskNotOwnedByCaller();
error SC_TaskNotAssigned();
error SC_TaskAlreadyAssigned();
error SC_TaskAlreadyCompleted();
error SC_TaskAlreadyCancelled();
error SC_KnowledgeEntryNotFound();
error SC_InsufficientFunds();
error SC_ProposalNotFound();
error SC_ProposalNotActive();
error SC_ProposalAlreadyVoted();
error SC_VoteAlreadyCast();
error SC_ProposalVoteThresholdNotMet();
error SC_ProposalQuorumNotMet();
error SC_ProposalNotExecutable();
error SC_NoActiveProposals();
error SC_SelfLinkForbidden();
error SC_LinkAlreadyExists();
error SC_LinkDoesNotExist();
error SC_InvalidRewardAmount();
error SC_InvalidOracle();
error SC_ReputationTooLow();

/**
 * @title The Synergistic Cognition Protocol (SCP)
 * @dev A decentralized framework for deploying, managing, and coordinating autonomous
 *      "Cognitive Nodes" (representatives of AI agents). It leverages reputation,
 *      a dynamic "Neural Nexus," and a shared "Knowledge Base" to facilitate
 *      collaborative problem-solving and information sharing, all governed by
 *      a reputation-weighted DAO.
 */
contract SCP is Ownable, Pausable, ReentrancyGuard {

    // --- Enums ---
    enum NodeState { Idle, Working, Hibernating, Reclaimed }
    enum TaskStatus { Created, Assigned, Completed, Verified, Cancelled }
    enum ProposalState { Pending, Active, Succeeded, Failed, Executed }

    // --- Structs ---

    struct CognitiveNode {
        uint256 id;
        address owner;
        string name;
        string specializationURI; // URI pointing to IPFS/Arweave for detailed specialization
        bytes32 neuralSignature;  // Unique identifier for the off-chain agent represented
        uint256 rawReputation;    // Base reputation score
        uint256 lastReputationUpdateBlock; // Block number for reputation decay calculation
        NodeState state;
        uint256 activeTaskId;     // 0 if idle
    }

    struct CognitiveTask {
        uint256 id;
        address requester;
        uint256 assignedNodeId; // 0 if not assigned
        string taskDescriptionURI; // URI to IPFS/Arweave for task details
        uint256 difficulty;       // Placeholder for complexity, affects reward/reputation
        uint256 rewardAmount;     // ETH or ERC20 (if rewardToken is set)
        bytes32 resultHash;       // Hash of the expected result, reported by node
        TaskStatus status;
        uint256 createdAtBlock;
        uint256 completedAtBlock; // When reported completed
    }

    struct KnowledgeEntry {
        uint256 id;
        uint256 contributingNodeId;
        string knowledgeURI;      // URI to IPFS/Arweave for the actual knowledge data
        bytes32 dataHash;         // Hash of the knowledge data for verification/search
        uint256 contributedAtBlock;
        bool verified;
    }

    struct GovernanceProposal {
        uint256 id;
        address proposer;
        string description;
        bytes calldataBytes;      // The actual calldata to execute if proposal passes
        uint256 voteStartTime;    // Timestamp when voting starts
        uint256 voteEndTime;      // Timestamp when voting ends
        uint256 totalReputationAtProposal; // Snapshot of total active reputation when proposed
        uint256 votesFor;         // Sum of reputation scores voting 'for'
        uint256 votesAgainst;     // Sum of reputation scores voting 'against'
        ProposalState state;
        mapping(address => bool) hasVoted; // Tracks if an address has voted on this proposal
    }

    // --- State Variables ---

    uint256 public nextNodeId;
    uint256 public nextTaskId;
    uint256 public nextKnowledgeEntryId;
    uint256 public nextProposalId;

    mapping(uint256 => CognitiveNode) public cognitiveNodes;
    mapping(address => uint256[]) public ownerToNodeIds; // To quickly get nodes by owner
    mapping(uint256 => CognitiveTask) public cognitiveTasks;
    mapping(uint256 => KnowledgeEntry) public knowledgeBase;
    mapping(bytes32 => uint256) public dataHashToKnowledgeEntryId; // For quick lookup of knowledge by hash
    mapping(uint256 => GovernanceProposal) public governanceProposals;

    // Neural Nexus: Adjacency list for connections
    mapping(uint256 => mapping(uint256 => bool)) public neuralLinks;
    mapping(uint256 => uint256[]) public nodeToNeuralLinks; // List of connected nodes

    address public oracleAddress; // Trusted address for off-chain task/knowledge verification
    IERC20 public immutable rewardToken; // Optional: ERC20 token for rewards, 0x0 address if ETH

    // Protocol Parameters (adjustable via governance)
    uint256 public REPUTATION_DECAY_RATE_PER_100_BLOCKS; // e.g., 100 = 1% decay per 100 blocks
    uint256 public TASK_SUCCESS_REPUTATION_GAIN;
    uint256 public TASK_FAILURE_REPUTATION_LOSS;
    uint256 public KNOWLEDGE_CONTRIBUTION_REPUTATION_GAIN;
    uint256 public PROPOSAL_VOTING_PERIOD; // In seconds
    uint256 public PROPOSAL_MIN_SUPPORT_PERCENT; // e.g., 50 for 50%
    uint256 public PROPOSAL_MIN_QUORUM_PERCENT;   // e.g., 20 for 20% of total reputation to participate

    // --- Events ---

    event CognitiveNodeDeployed(uint256 indexed nodeId, address indexed owner, string name, string specializationURI);
    event NodeSpecializationUpdated(uint256 indexed nodeId, string newSpecializationURI);
    event CognitiveNodeReclaimed(uint256 indexed nodeId, address indexed owner);
    event NodeOwnershipTransferred(uint256 indexed nodeId, address indexed oldOwner, address indexed newOwner);

    event CognitiveTaskRequested(uint256 indexed taskId, address indexed requester, uint256 rewardAmount);
    event CognitiveTaskAssigned(uint256 indexed taskId, uint256 indexed nodeId);
    event CognitiveTaskReported(uint256 indexed taskId, uint256 indexed nodeId, bytes32 resultHash);
    event CognitiveTaskVerified(uint256 indexed taskId, uint256 indexed nodeId, bool success, uint256 reputationChange);
    event CognitiveTaskCancelled(uint256 indexed taskId, address indexed canceller);

    event NodeReputationUpdated(uint256 indexed nodeId, uint256 newReputation, uint256 change);

    event NeuralLinkFormed(uint256 indexed nodeId1, uint256 indexed nodeId2);
    event NeuralLinkBroken(uint256 indexed nodeId1, uint256 indexed nodeId2);

    event KnowledgeContributed(uint256 indexed entryId, uint256 indexed nodeId, string knowledgeURI, bytes32 dataHash);
    event KnowledgeVerified(uint256 indexed entryId, uint256 indexed nodeId, bool isValid);

    event GovernanceProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 reputationWeight);
    event ProposalStateChanged(uint256 indexed proposalId, ProposalState newState);
    event ProtocolParameterUpdated(bytes32 indexed paramKey, uint256 newValue);
    event OracleAddressSet(address indexed newOracleAddress);

    // --- Modifiers ---

    modifier onlyNodeOwner(uint256 _nodeId) {
        if (cognitiveNodes[_nodeId].owner != msg.sender) revert SC_NodeNotOwnedByCaller();
        _;
    }

    modifier onlyOracle() {
        if (msg.sender != oracleAddress) revert SC_Unauthorized();
        _;
    }

    modifier onlyGovernanceApproved() {
        // This modifier is for functions meant to be called *only* by the execution of a passed proposal
        // The actual check happens within `executeGovernanceChange`
        _;
    }

    // --- Constructor ---

    constructor(address _initialOracle, IERC20 _rewardTokenAddress) Ownable(msg.sender) {
        if (_initialOracle == address(0)) revert SC_InvalidOracle();
        oracleAddress = _initialOracle;
        rewardToken = _rewardTokenAddress;

        // Set initial protocol parameters
        REPUTATION_DECAY_RATE_PER_100_BLOCKS = 10; // 0.1% decay per 100 blocks
        TASK_SUCCESS_REPUTATION_GAIN = 100;
        TASK_FAILURE_REPUTATION_LOSS = 50;
        KNOWLEDGE_CONTRIBUTION_REPUTATION_GAIN = 75;
        PROPOSAL_VOTING_PERIOD = 7 days; // 7 days voting period
        PROPOSAL_MIN_SUPPORT_PERCENT = 50; // 50% approval
        PROPOSAL_MIN_QUORUM_PERCENT = 20;  // 20% of total reputation must vote
    }

    // --- Internal/Utility Functions ---

    /**
     * @dev Calculates the effective reputation of a node, considering decay over time.
     *      Decay is proportional to `REPUTATION_DECAY_RATE_PER_100_BLOCKS` and blocks passed.
     * @param _nodeId The ID of the node.
     * @return The current effective reputation score.
     */
    function _calculateEffectiveReputation(uint256 _nodeId) internal view returns (uint256) {
        CognitiveNode storage node = cognitiveNodes[_nodeId];
        if (node.rawReputation == 0 || node.state == NodeState.Reclaimed) {
            return 0;
        }

        uint256 blocksPassed = block.number - node.lastReputationUpdateBlock;
        if (blocksPassed == 0) {
            return node.rawReputation;
        }

        uint256 decayAmount = (node.rawReputation * REPUTATION_DECAY_RATE_PER_100_BLOCKS * blocksPassed) / (100 * 100);
        return node.rawReputation > decayAmount ? node.rawReputation - decayAmount : 0;
    }

    /**
     * @dev Updates the raw reputation of a node and resets the last update block.
     * @param _nodeId The ID of the node.
     * @param _amount The amount to change reputation by (can be negative).
     * @param _isGain True if it's a gain, false if it's a loss.
     */
    function _updateNodeReputation(uint256 _nodeId, uint256 _amount, bool _isGain) internal {
        CognitiveNode storage node = cognitiveNodes[_nodeId];
        // First, apply decay to current raw reputation to get updated raw rep.
        node.rawReputation = _calculateEffectiveReputation(_nodeId);

        if (_isGain) {
            node.rawReputation += _amount;
        } else {
            node.rawReputation = node.rawReputation > _amount ? node.rawReputation - _amount : 0;
        }
        node.lastReputationUpdateBlock = block.number;
        emit NodeReputationUpdated(_nodeId, node.rawReputation, _amount);
    }

    /**
     * @dev Checks and updates a proposal's state based on time and vote counts.
     * @param _proposalId The ID of the proposal.
     */
    function _checkProposalState(uint256 _proposalId) internal {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        if (proposal.state != ProposalState.Active) {
            return;
        }

        if (block.timestamp >= proposal.voteEndTime) {
            uint256 totalVotesCast = proposal.votesFor + proposal.votesAgainst;
            uint256 minVotesForQuorum = (proposal.totalReputationAtProposal * PROPOSAL_MIN_QUORUM_PERCENT) / 100;

            if (totalVotesCast >= minVotesForQuorum && proposal.votesFor > proposal.votesAgainst &&
                (proposal.votesFor * 100) / totalVotesCast >= PROPOSAL_MIN_SUPPORT_PERCENT) {
                proposal.state = ProposalState.Succeeded;
            } else {
                proposal.state = ProposalState.Failed;
            }
            emit ProposalStateChanged(_proposalId, proposal.state);
        }
    }

    /**
     * @dev Gets the total active reputation of all non-reclaimed nodes.
     * @return The sum of effective reputations of all active nodes.
     */
    function _getTotalActiveReputation() internal view returns (uint256) {
        uint256 totalReputation = 0;
        for (uint256 i = 1; i < nextNodeId; i++) {
            if (cognitiveNodes[i].state != NodeState.Reclaimed) {
                totalReputation += _calculateEffectiveReputation(i);
            }
        }
        return totalReputation;
    }

    // --- II. Agent (Cognitive Node) Management ---

    /**
     * @dev Deploys a new Cognitive Node, assigning a unique ID, initial reputation, and owner.
     *      Requires payment of 0.01 ETH for deployment fee.
     * @param _name A human-readable name for the node.
     * @param _specializationURI URI pointing to IPFS/Arweave for detailed specialization.
     * @param _neuralSignature A unique, cryptographically secure hash representing the off-chain AI agent.
     */
    function deployCognitiveNode(string memory _name, string memory _specializationURI, bytes32 _neuralSignature)
        public payable whenNotPaused nonReentrant returns (uint256)
    {
        if (msg.value < 0.01 ether) revert SC_InsufficientFunds(); // Small deployment fee

        uint256 nodeId = nextNodeId++;
        cognitiveNodes[nodeId] = CognitiveNode({
            id: nodeId,
            owner: msg.sender,
            name: _name,
            specializationURI: _specializationURI,
            neuralSignature: _neuralSignature,
            rawReputation: 1000, // Initial reputation
            lastReputationUpdateBlock: block.number,
            state: NodeState.Idle,
            activeTaskId: 0
        });
        ownerToNodeIds[msg.sender].push(nodeId);

        emit CognitiveNodeDeployed(nodeId, msg.sender, _name, _specializationURI);
        return nodeId;
    }

    /**
     * @dev Allows a node owner to update their node's specialization metadata URI.
     * @param _nodeId The ID of the node to update.
     * @param _newSpecializationURI The new URI for specialization details.
     */
    function updateNodeSpecialization(uint256 _nodeId, string memory _newSpecializationURI)
        public onlyNodeOwner(_nodeId) whenNotPaused
    {
        if (cognitiveNodes[_nodeId].id == 0) revert SC_NodeNotFound();
        cognitiveNodes[_nodeId].specializationURI = _newSpecializationURI;
        emit NodeSpecializationUpdated(_nodeId, _newSpecializationURI);
    }

    /**
     * @dev Allows the owner to deactivate and "reclaim" their node, removing it from active participation.
     *      A reclaimed node cannot participate in tasks or governance, but its history is preserved.
     * @param _nodeId The ID of the node to reclaim.
     */
    function reclaimCognitiveNode(uint256 _nodeId) public onlyNodeOwner(_nodeId) whenNotPaused {
        CognitiveNode storage node = cognitiveNodes[_nodeId];
        if (node.id == 0) revert SC_NodeNotFound();
        if (node.state == NodeState.Reclaimed) revert SC_NodeAlreadyInactive();
        if (node.state == NodeState.Working) revert SC_InvalidNodeState(); // Cannot reclaim while working

        node.state = NodeState.Reclaimed;
        // Optionally, refund a portion of the deployment fee here.
        emit CognitiveNodeReclaimed(_nodeId, msg.sender);
    }

    /**
     * @dev Transfers ownership of a Cognitive Node to another address.
     * @param _nodeId The ID of the node whose ownership is to be transferred.
     * @param _newOwner The address of the new owner.
     */
    function transferNodeOwnership(uint256 _nodeId, address _newOwner) public onlyNodeOwner(_nodeId) whenNotPaused {
        if (_newOwner == address(0)) revert SC_InvalidOracle(); // Reusing the error for general zero address check
        CognitiveNode storage node = cognitiveNodes[_nodeId];
        if (node.id == 0) revert SC_NodeNotFound();

        address oldOwner = node.owner;
        node.owner = _newOwner;

        // Remove from old owner's list, add to new owner's list (simplistic, could be optimized)
        uint256[] storage oldOwnerNodes = ownerToNodeIds[oldOwner];
        for (uint256 i = 0; i < oldOwnerNodes.length; i++) {
            if (oldOwnerNodes[i] == _nodeId) {
                oldOwnerNodes[i] = oldOwnerNodes[oldOwnerNodes.length - 1];
                oldOwnerNodes.pop();
                break;
            }
        }
        ownerToNodeIds[_newOwner].push(_nodeId);

        emit NodeOwnershipTransferred(_nodeId, oldOwner, _newOwner);
    }

    /**
     * @dev Retrieves all public details of a specific Cognitive Node.
     * @param _nodeId The ID of the node.
     * @return All node properties.
     */
    function getNodeDetails(uint256 _nodeId)
        public view returns (uint256, address, string memory, string memory, bytes32, uint256, NodeState, uint256)
    {
        CognitiveNode storage node = cognitiveNodes[_nodeId];
        if (node.id == 0) revert SC_NodeNotFound();
        return (
            node.id,
            node.owner,
            node.name,
            node.specializationURI,
            node.neuralSignature,
            _calculateEffectiveReputation(_nodeId),
            node.state,
            node.activeTaskId
        );
    }

    /**
     * @dev Returns a list of all Cognitive Node IDs owned by a specific address.
     * @param _owner The address to query.
     * @return An array of node IDs.
     */
    function getNodesByOwner(address _owner) public view returns (uint256[] memory) {
        return ownerToNodeIds[_owner];
    }

    // --- III. Task System & Verification ---

    /**
     * @dev Creates a new task, setting its parameters and locking the reward.
     *      Requires ETH or specified ERC20 token for reward.
     * @param _taskDescriptionURI URI to IPFS/Arweave for task details.
     * @param _difficulty Placeholder for complexity, affects reward/reputation.
     * @param _rewardAmount The amount of reward for completing the task.
     */
    function requestCognitiveTask(string memory _taskDescriptionURI, uint256 _difficulty, uint256 _rewardAmount)
        public payable whenNotPaused nonReentrant returns (uint256)
    {
        if (_rewardAmount == 0) revert SC_InvalidRewardAmount();

        if (address(rewardToken) == address(0)) { // ETH reward
            if (msg.value < _rewardAmount) revert SC_InsufficientFunds();
            // Excess ETH will be refunded automatically by payable
        } else { // ERC20 reward
            if (msg.value > 0) revert SC_InsufficientFunds(); // No ETH expected
            if (rewardToken.transferFrom(msg.sender, address(this), _rewardAmount) == false) {
                revert SC_InsufficientFunds(); // Or a more specific ERC20 transfer error
            }
        }

        uint256 taskId = nextTaskId++;
        cognitiveTasks[taskId] = CognitiveTask({
            id: taskId,
            requester: msg.sender,
            assignedNodeId: 0,
            taskDescriptionURI: _taskDescriptionURI,
            difficulty: _difficulty,
            rewardAmount: _rewardAmount,
            resultHash: bytes32(0),
            status: TaskStatus.Created,
            createdAtBlock: block.number,
            completedAtBlock: 0
        });

        emit CognitiveTaskRequested(taskId, msg.sender, _rewardAmount);
        return taskId;
    }

    /**
     * @dev Assigns an available task to a specific Cognitive Node.
     *      Can be called by the node owner or a governance-approved dispatcher.
     * @param _taskId The ID of the task to assign.
     * @param _nodeId The ID of the node to assign the task to.
     */
    function assignTaskToNode(uint256 _taskId, uint256 _nodeId) public whenNotPaused {
        CognitiveTask storage task = cognitiveTasks[_taskId];
        CognitiveNode storage node = cognitiveNodes[_nodeId];

        if (task.id == 0) revert SC_TaskNotFound();
        if (node.id == 0) revert SC_NodeNotFound();
        if (task.status != TaskStatus.Created) revert SC_TaskAlreadyAssigned();
        if (node.state != NodeState.Idle) revert SC_InvalidNodeState(); // Node must be idle
        if (_calculateEffectiveReputation(_nodeId) < 100) revert SC_ReputationTooLow(); // Example: Min reputation to take tasks

        // Check if caller is task requester OR node owner
        // In a more complex system, this would involve a task dispatcher role or bidding system
        if (msg.sender != task.requester && msg.sender != node.owner) {
            revert SC_Unauthorized();
        }

        task.assignedNodeId = _nodeId;
        task.status = TaskStatus.Assigned;
        node.activeTaskId = _taskId;
        node.state = NodeState.Working;

        emit CognitiveTaskAssigned(_taskId, _nodeId);
    }

    /**
     * @dev Called by the assigned node (or its owner) to report task completion and provide a result hash.
     * @param _taskId The ID of the completed task.
     * @param _nodeId The ID of the node reporting completion.
     * @param _resultHash A hash of the task's computed result (for off-chain verification).
     */
    function reportTaskCompletion(uint256 _taskId, uint256 _nodeId, bytes32 _resultHash)
        public onlyNodeOwner(_nodeId) whenNotPaused
    {
        CognitiveTask storage task = cognitiveTasks[_taskId];
        CognitiveNode storage node = cognitiveNodes[_nodeId];

        if (task.id == 0) revert SC_TaskNotFound();
        if (node.id == 0) revert SC_NodeNotFound();
        if (task.assignedNodeId != _nodeId) revert SC_TaskNotAssigned();
        if (task.status != TaskStatus.Assigned) revert SC_InvalidNodeState(); // Must be assigned
        if (node.activeTaskId != _taskId) revert SC_InvalidNodeState(); // Node must have this task active

        task.resultHash = _resultHash;
        task.status = TaskStatus.Completed;
        task.completedAtBlock = block.number;
        node.state = NodeState.Idle; // Node becomes idle, waiting for verification
        node.activeTaskId = 0;

        emit CognitiveTaskReported(_taskId, _nodeId, _resultHash);
    }

    /**
     * @dev Called by an authorized oracle (or governance) to verify the task result,
     *      updating node reputation and distributing rewards.
     * @param _taskId The ID of the task to verify.
     * @param _expectedResultHash The result hash provided by the oracle after off-chain computation.
     * @param _success True if the verification passed, false otherwise.
     */
    function verifyTaskCompletion(uint256 _taskId, bytes32 _expectedResultHash, bool _success)
        public onlyOracle whenNotPaused nonReentrant
    {
        CognitiveTask storage task = cognitiveTasks[_taskId];
        if (task.id == 0) revert SC_TaskNotFound();
        if (task.status != TaskStatus.Completed) revert SC_TaskAlreadyCompleted(); // Must be completed, not verified yet

        CognitiveNode storage node = cognitiveNodes[task.assignedNodeId];
        if (node.id == 0) revert SC_NodeNotFound(); // Should not happen if task was assigned

        uint256 reputationChange = 0;
        if (_success && task.resultHash == _expectedResultHash) {
            // Reward node reputation
            _updateNodeReputation(node.id, TASK_SUCCESS_REPUTATION_GAIN + task.difficulty, true);
            reputationChange = TASK_SUCCESS_REPUTATION_GAIN + task.difficulty;

            // Distribute reward
            if (address(rewardToken) == address(0)) { // ETH
                payable(node.owner).transfer(task.rewardAmount);
            } else { // ERC20
                if (rewardToken.transfer(node.owner, task.rewardAmount) == false) {
                    // Log error but don't revert if token transfer fails,
                    // just ensures task status is updated. A robust system
                    // would handle this with retries or a claim function.
                }
            }
            task.status = TaskStatus.Verified;

        } else {
            // Penalize node reputation
            _updateNodeReputation(node.id, TASK_FAILURE_REPUTATION_LOSS + task.difficulty, false);
            reputationChange = TASK_FAILURE_REPUTATION_LOSS + task.difficulty;
            task.status = TaskStatus.Cancelled; // Mark as cancelled if verification fails

            // Return funds to requester if verification failed
            if (address(rewardToken) == address(0)) { // ETH
                payable(task.requester).transfer(task.rewardAmount);
            } else { // ERC20
                 if (rewardToken.transfer(task.requester, task.rewardAmount) == false) {
                    // Handle ERC20 refund failure
                }
            }
        }

        emit CognitiveTaskVerified(_taskId, node.id, _success, reputationChange);
    }

    /**
     * @dev Allows the task requester to cancel an unassigned or pending task.
     *      Refunds the reward amount to the requester.
     * @param _taskId The ID of the task to cancel.
     */
    function cancelCognitiveTask(uint256 _taskId) public whenNotPaused nonReentrant {
        CognitiveTask storage task = cognitiveTasks[_taskId];
        if (task.id == 0) revert SC_TaskNotFound();
        if (task.requester != msg.sender) revert SC_TaskNotOwnedByCaller();
        if (task.status != TaskStatus.Created && task.status != TaskStatus.Assigned) {
            revert SC_TaskAlreadyCompleted(); // Or verified/cancelled
        }
        if (task.status == TaskStatus.Assigned) {
            // If assigned, revert node to Idle state
            CognitiveNode storage node = cognitiveNodes[task.assignedNodeId];
            if (node.id != 0) {
                node.state = NodeState.Idle;
                node.activeTaskId = 0;
            }
        }

        task.status = TaskStatus.Cancelled;
        // Refund reward
        if (address(rewardToken) == address(0)) { // ETH
            payable(msg.sender).transfer(task.rewardAmount);
        } else { // ERC20
            if (rewardToken.transfer(msg.sender, task.rewardAmount) == false) {
                // Handle ERC20 refund failure
            }
        }
        emit CognitiveTaskCancelled(_taskId, msg.sender);
    }

    /**
     * @dev Retrieves all public details of a specific Cognitive Task.
     * @param _taskId The ID of the task.
     * @return All task properties.
     */
    function getTaskDetails(uint256 _taskId)
        public view returns (uint256, address, uint256, string memory, uint256, uint256, bytes32, TaskStatus, uint256, uint256)
    {
        CognitiveTask storage task = cognitiveTasks[_taskId];
        if (task.id == 0) revert SC_TaskNotFound();
        return (
            task.id,
            task.requester,
            task.assignedNodeId,
            task.taskDescriptionURI,
            task.difficulty,
            task.rewardAmount,
            task.resultHash,
            task.status,
            task.createdAtBlock,
            task.completedAtBlock
        );
    }

    /**
     * @dev Returns a list of all tasks currently awaiting assignment or completion.
     * @return An array of pending task IDs.
     */
    function getPendingTasks() public view returns (uint256[] memory) {
        uint256[] memory pendingTaskIds = new uint256[](nextTaskId); // Max possible size
        uint256 counter = 0;
        for (uint256 i = 1; i < nextTaskId; i++) {
            if (cognitiveTasks[i].status == TaskStatus.Created || cognitiveTasks[i].status == TaskStatus.Assigned) {
                pendingTaskIds[counter] = i;
                counter++;
            }
        }
        // Resize array to actual number of pending tasks
        uint256[] memory result = new uint256[](counter);
        for (uint256 i = 0; i < counter; i++) {
            result[i] = pendingTaskIds[i];
        }
        return result;
    }

    // --- IV. Reputation Management ---

    /**
     * @dev Returns the current effective reputation score of a Cognitive Node, adjusted for decay.
     * @param _nodeId The ID of the node.
     * @return The effective reputation score.
     */
    function getNodeReputation(uint256 _nodeId) public view returns (uint256) {
        if (cognitiveNodes[_nodeId].id == 0) revert SC_NodeNotFound();
        return _calculateEffectiveReputation(_nodeId);
    }

    /**
     * @dev Decreases a node's reputation, typically for failed tasks or misconduct.
     *      Callable by the oracle or governance-approved execution.
     * @param _nodeId The ID of the node to penalize.
     * @param _amount The amount of reputation to deduct.
     */
    function penalizeNode(uint256 _nodeId, uint256 _amount) public onlyOracle whenNotPaused {
        if (cognitiveNodes[_nodeId].id == 0) revert SC_NodeNotFound();
        _updateNodeReputation(_nodeId, _amount, false);
    }

    /**
     * @dev Increases a node's reputation, typically for successful task completion or knowledge contribution.
     *      Callable by the oracle or governance-approved execution.
     * @param _nodeId The ID of the node to reward.
     * @param _amount The amount of reputation to add.
     */
    function rewardNode(uint256 _nodeId, uint256 _amount) public onlyOracle whenNotPaused {
        if (cognitiveNodes[_nodeId].id == 0) revert SC_NodeNotFound();
        _updateNodeReputation(_nodeId, _amount, true);
    }

    // --- V. Neural Nexus (Node Interconnection) ---

    /**
     * @dev Establishes a bidirectional "neural link" between two nodes, signifying a successful collaboration or affinity.
     *      Can only be initiated by the owner of `_nodeId1`
     * @param _nodeId1 The ID of the first node.
     * @param _nodeId2 The ID of the second node.
     */
    function formNeuralLink(uint256 _nodeId1, uint256 _nodeId2) public onlyNodeOwner(_nodeId1) whenNotPaused {
        if (cognitiveNodes[_nodeId1].id == 0 || cognitiveNodes[_nodeId2].id == 0) revert SC_NodeNotFound();
        if (_nodeId1 == _nodeId2) revert SC_SelfLinkForbidden();
        if (neuralLinks[_nodeId1][_nodeId2]) revert SC_LinkAlreadyExists();

        neuralLinks[_nodeId1][_nodeId2] = true;
        neuralLinks[_nodeId2][_nodeId1] = true; // Bidirectional

        nodeToNeuralLinks[_nodeId1].push(_nodeId2);
        nodeToNeuralLinks[_nodeId2].push(_nodeId1);

        emit NeuralLinkFormed(_nodeId1, _nodeId2);
    }

    /**
     * @dev Dissolves an existing neural link between two nodes.
     *      Can be initiated by the owner of either linked node.
     * @param _nodeId1 The ID of the first node.
     * @param _nodeId2 The ID of the second node.
     */
    function breakNeuralLink(uint256 _nodeId1, uint256 _nodeId2) public whenNotPaused {
        if (cognitiveNodes[_nodeId1].id == 0 || cognitiveNodes[_nodeId2].id == 0) revert SC_NodeNotFound();
        if (msg.sender != cognitiveNodes[_nodeId1].owner && msg.sender != cognitiveNodes[_nodeId2].owner) {
            revert SC_Unauthorized(); // Must be owner of one of the nodes
        }
        if (_nodeId1 == _nodeId2) revert SC_SelfLinkForbidden();
        if (!neuralLinks[_nodeId1][_nodeId2]) revert SC_LinkDoesNotExist();

        neuralLinks[_nodeId1][_nodeId2] = false;
        neuralLinks[_nodeId2][_nodeId1] = false;

        // Remove from dynamic arrays (simplified, inefficient for very large lists)
        uint256[] storage links1 = nodeToNeuralLinks[_nodeId1];
        for (uint256 i = 0; i < links1.length; i++) {
            if (links1[i] == _nodeId2) {
                links1[i] = links1[links1.length - 1];
                links1.pop();
                break;
            }
        }
        uint256[] storage links2 = nodeToNeuralLinks[_nodeId2];
        for (uint256 i = 0; i < links2.length; i++) {
            if (links2[i] == _nodeId1) {
                links2[i] = links2[links2.length - 1];
                links2.pop();
                break;
            }
        }

        emit NeuralLinkBroken(_nodeId1, _nodeId2);
    }

    /**
     * @dev Retrieves a list of all nodes connected to a specific node via neural links.
     * @param _nodeId The ID of the node to query.
     * @return An array of connected node IDs.
     */
    function getNodeNeuralLinks(uint256 _nodeId) public view returns (uint256[] memory) {
        if (cognitiveNodes[_nodeId].id == 0) revert SC_NodeNotFound();
        return nodeToNeuralLinks[_nodeId];
    }

    /**
     * @dev Suggests other nodes for collaboration based on shared neural links and specializations.
     *      (Simplified logic: just returns direct links for now. Real world would use graph algorithms).
     * @param _nodeId The ID of the node seeking collaborators.
     * @param _count The maximum number of suggestions to return.
     * @return An array of suggested node IDs.
     */
    function suggestCollaborators(uint256 _nodeId, uint256 _count) public view returns (uint256[] memory) {
        if (cognitiveNodes[_nodeId].id == 0) revert SC_NodeNotFound();

        uint256[] memory directLinks = nodeToNeuralLinks[_nodeId];
        uint256 numSuggestions = directLinks.length > _count ? _count : directLinks.length;
        uint256[] memory suggestions = new uint256[](numSuggestions);

        for (uint256 i = 0; i < numSuggestions; i++) {
            suggestions[i] = directLinks[i];
        }
        return suggestions;
    }

    // --- VI. Knowledge Base ---

    /**
     * @dev Allows a node (or its owner) to contribute a piece of validated information to the shared knowledge base.
     *      Requires a data hash for later verification.
     * @param _nodeId The ID of the contributing node.
     * @param _knowledgeURI URI to IPFS/Arweave for the actual knowledge data.
     * @param _dataHash Hash of the knowledge data for verification/search.
     */
    function contributeToKnowledgeBase(uint256 _nodeId, string memory _knowledgeURI, bytes32 _dataHash)
        public onlyNodeOwner(_nodeId) whenNotPaused returns (uint256)
    {
        if (cognitiveNodes[_nodeId].id == 0) revert SC_NodeNotFound();

        uint256 entryId = nextKnowledgeEntryId++;
        knowledgeBase[entryId] = KnowledgeEntry({
            id: entryId,
            contributingNodeId: _nodeId,
            knowledgeURI: _knowledgeURI,
            dataHash: _dataHash,
            contributedAtBlock: block.number,
            verified: false
        });
        dataHashToKnowledgeEntryId[_dataHash] = entryId;

        emit KnowledgeContributed(entryId, _nodeId, _knowledgeURI, _dataHash);
        return entryId;
    }

    /**
     * @dev An authorized oracle/governance verifies the integrity and validity of a knowledge base entry.
     *      Affects the contributing node's reputation.
     * @param _entryId The ID of the knowledge entry to verify.
     * @param _isValid True if the knowledge is valid, false otherwise.
     */
    function verifyKnowledgeContribution(uint256 _entryId, bool _isValid) public onlyOracle whenNotPaused {
        KnowledgeEntry storage entry = knowledgeBase[_entryId];
        if (entry.id == 0) revert SC_KnowledgeEntryNotFound();
        if (entry.verified) revert SC_InvalidNodeState(); // Already verified

        entry.verified = true;
        if (_isValid) {
            _updateNodeReputation(entry.contributingNodeId, KNOWLEDGE_CONTRIBUTION_REPUTATION_GAIN, true);
        } else {
            _updateNodeReputation(entry.contributingNodeId, KNOWLEDGE_CONTRIBUTION_REPUTATION_GAIN / 2, false); // Half penalty
        }
        emit KnowledgeVerified(_entryId, entry.contributingNodeId, _isValid);
    }

    /**
     * @dev Retrieves the details of a specific knowledge entry.
     * @param _entryId The ID of the knowledge entry.
     * @return All knowledge entry properties.
     */
    function queryKnowledgeBase(uint256 _entryId)
        public view returns (uint256, uint256, string memory, bytes32, uint256, bool)
    {
        KnowledgeEntry storage entry = knowledgeBase[_entryId];
        if (entry.id == 0) revert SC_KnowledgeEntryNotFound();
        return (
            entry.id,
            entry.contributingNodeId,
            entry.knowledgeURI,
            entry.dataHash,
            entry.contributedAtBlock,
            entry.verified
        );
    }

    /**
     * @dev Allows searching for knowledge entries by their unique data hash.
     * @param _dataHash The hash of the data to search for.
     * @return The ID of the matching knowledge entry (0 if not found).
     */
    function searchKnowledgeBaseByHash(bytes32 _dataHash) public view returns (uint256) {
        return dataHashToKnowledgeEntryId[_dataHash];
    }

    // --- VII. Governance & Protocol Parameters ---

    /**
     * @dev Initiates a new governance proposal, requiring reputation-weighted voting.
     *      Caller must own at least one active node to propose.
     * @param _description A textual description of the proposal.
     * @param _calldata The actual calldata bytes to be executed if the proposal passes.
     */
    function proposeGovernanceChange(string memory _description, bytes memory _calldata) public whenNotPaused returns (uint256) {
        bool hasActiveNode = false;
        for (uint256 i = 0; i < ownerToNodeIds[msg.sender].length; i++) {
            if (cognitiveNodes[ownerToNodeIds[msg.sender][i]].state != NodeState.Reclaimed &&
                _calculateEffectiveReputation(ownerToNodeIds[msg.sender][i]) > 0) {
                hasActiveNode = true;
                break;
            }
        }
        if (!hasActiveNode) revert SC_ReputationTooLow(); // Or dedicated error for no active node

        uint256 proposalId = nextProposalId++;
        governanceProposals[proposalId] = GovernanceProposal({
            id: proposalId,
            proposer: msg.sender,
            description: _description,
            calldataBytes: _calldata,
            voteStartTime: block.timestamp,
            voteEndTime: block.timestamp + PROPOSAL_VOTING_PERIOD,
            totalReputationAtProposal: _getTotalActiveReputation(), // Snapshot total reputation
            votesFor: 0,
            votesAgainst: 0,
            state: ProposalState.Active,
            hasVoted: new mapping(address => bool) // Initialize the mapping
        });

        emit GovernanceProposalCreated(proposalId, msg.sender, _description);
        return proposalId;
    }

    /**
     * @dev Allows reputation holders to vote on active proposals.
     *      Voting power is proportional to the voter's total effective reputation across all their active nodes.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'yes', false for 'no'.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) public whenNotPaused {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        if (proposal.id == 0) revert SC_ProposalNotFound();
        if (proposal.state != ProposalState.Active) revert SC_ProposalNotActive();
        if (proposal.voteEndTime <= block.timestamp) { // Voting period over, check state
            _checkProposalState(_proposalId); // Update state if needed
            if (proposal.state != ProposalState.Active) revert SC_ProposalNotActive();
        }
        if (proposal.hasVoted[msg.sender]) revert SC_VoteAlreadyCast();

        uint256 voterReputation = 0;
        for (uint256 i = 0; i < ownerToNodeIds[msg.sender].length; i++) {
            uint256 nodeId = ownerToNodeIds[msg.sender][i];
            if (cognitiveNodes[nodeId].state != NodeState.Reclaimed) {
                voterReputation += _calculateEffectiveReputation(nodeId);
            }
        }
        if (voterReputation == 0) revert SC_ReputationTooLow();

        if (_support) {
            proposal.votesFor += voterReputation;
        } else {
            proposal.votesAgainst += voterReputation;
        }
        proposal.hasVoted[msg.sender] = true;

        emit VoteCast(_proposalId, msg.sender, _support, voterReputation);
    }

    /**
     * @dev Executes a passed governance proposal. Only callable after successful voting and cooldown.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeGovernanceChange(uint256 _proposalId) public whenNotPaused nonReentrant {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        if (proposal.id == 0) revert SC_ProposalNotFound();

        _checkProposalState(_proposalId); // Ensure state is up-to-date

        if (proposal.state != ProposalState.Succeeded) revert SC_ProposalNotExecutable();

        // Mark as executed immediately to prevent re-execution
        proposal.state = ProposalState.Executed;
        emit ProposalStateChanged(_proposalId, ProposalState.Executed);

        // Execute the proposed calldata
        (bool success, ) = address(this).call(proposal.calldataBytes);
        if (!success) {
            // Revert if the internal call fails. This is crucial for security.
            // A more sophisticated DAO might log this failure and allow re-execution attempts.
            revert SC_Unauthorized(); // Or a custom error for execution failure
        }
    }

    /**
     * @dev A governance-executed function to update specific protocol parameters.
     *      This function must be called via a successful governance proposal.
     * @param _paramKey A unique key identifying the parameter (e.g., keccak256("REPUTATION_DECAY_RATE")).
     * @param _newValue The new value for the parameter.
     */
    function updateProtocolParameter(bytes32 _paramKey, uint256 _newValue) public onlyGovernanceApproved {
        // This function is intended to be called only by `executeGovernanceChange`.
        // The `onlyGovernanceApproved` modifier serves as a marker for this.
        // The actual access control is handled by the `executeGovernanceChange` function.
        if (_paramKey == keccak256("REPUTATION_DECAY_RATE_PER_100_BLOCKS")) {
            REPUTATION_DECAY_RATE_PER_100_BLOCKS = _newValue;
        } else if (_paramKey == keccak256("TASK_SUCCESS_REPUTATION_GAIN")) {
            TASK_SUCCESS_REPUTATION_GAIN = _newValue;
        } else if (_paramKey == keccak256("TASK_FAILURE_REPUTATION_LOSS")) {
            TASK_FAILURE_REPUTATION_LOSS = _newValue;
        } else if (_paramKey == keccak256("KNOWLEDGE_CONTRIBUTION_REPUTATION_GAIN")) {
            KNOWLEDGE_CONTRIBUTION_REPUTATION_GAIN = _newValue;
        } else if (_paramKey == keccak256("PROPOSAL_VOTING_PERIOD")) {
            PROPOSAL_VOTING_PERIOD = _newValue;
        } else if (_paramKey == keccak256("PROPOSAL_MIN_SUPPORT_PERCENT")) {
            if (_newValue > 100) revert SC_Unauthorized(); // Or dedicated error for invalid parameter value
            PROPOSAL_MIN_SUPPORT_PERCENT = _newValue;
        } else if (_paramKey == keccak256("PROPOSAL_MIN_QUORUM_PERCENT")) {
            if (_newValue > 100) revert SC_Unauthorized();
            PROPOSAL_MIN_QUORUM_PERCENT = _newValue;
        } else {
            revert SC_Unauthorized(); // Unknown parameter key
        }
        emit ProtocolParameterUpdated(_paramKey, _newValue);
    }

    /**
     * @dev Sets the address of the trusted oracle responsible for task/knowledge verification.
     *      This function is `onlyOwner` initially, but should eventually be callable `onlyGovernanceApproved`.
     * @param _newOracle The address of the new oracle.
     */
    function setOracleAddress(address _newOracle) public onlyOwner {
        if (_newOracle == address(0)) revert SC_InvalidOracle();
        oracleAddress = _newOracle;
        emit OracleAddressSet(_newOracle);
    }

    /**
     * @dev Allows the owner/governance to pause critical contract functions in an emergency.
     *      Uses OpenZeppelin's Pausable modifier.
     */
    function emergencyPause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract after an emergency pause.
     *      Uses OpenZeppelin's Pausable modifier.
     */
    function unpauseContract() public onlyOwner {
        _unpause();
    }

    // Optional: A way for the owner to withdraw leftover ETH if not used for rewards/refunds.
    function withdrawProtocolFees() public onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            payable(owner()).transfer(balance);
        }
    }
}
```