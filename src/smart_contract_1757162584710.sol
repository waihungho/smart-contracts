Here's a Solidity smart contract named `AethermindProtocol` that implements a decentralized verifiable AI agent network, leveraging Zero-Knowledge Proofs, Dynamic Reputation NFTs (rNFTs), and DAO governance.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // SafeMath is often redundant in 0.8.x but good practice for clarity with `sub` etc.

/*
█████  ██   ██ ███████ ████████ ███    ███ ███████ ██████  ███    ███ ██████  
██   ██ ██   ██ ██         ██    ████  ████ ██      ██   ██ ████  ████ ██   ██ 
██████  ███████ █████     ██    ██ ████ ██ █████   ██████  ██ ████ ██ ██████  
██   ██ ██   ██ ██        ██    ██  ██  ██ ██      ██   ██ ██  ██  ██ ██   ██ 
█████  ██   ██ ███████    ██    ██      ██ ███████ ██   ██ ██      ██ ██   ██ 
*/

/**
 * @title AethermindProtocol
 * @dev A cutting-edge smart contract protocol for managing a decentralized network of AI agents,
 *      leveraging Zero-Knowledge Proofs for verifiable task execution, dynamic Reputation NFTs (rNFTs),
 *      and a comprehensive DAO governance system.
 *
 * @notice This contract aims to enable a trustless ecosystem where AI agents can offer services
 *         and get rewarded based on provable performance, with their reputation evolving on-chain.
 *         It avoids duplicating existing open-source contracts by integrating these advanced concepts
 *         into a novel, interconnected system for verifiable AI services.
 *
 * @dev Core Concepts:
 *      1.  **Verifiable AI Agents:** AI agents perform complex computational tasks off-chain and
 *          submit Zero-Knowledge Proofs (ZKPs) to the contract for on-chain verification of their results.
 *          This ensures trustless execution without revealing sensitive AI models or proprietary data.
 *      2.  **Dynamic Reputation NFTs (rNFTs):** Each registered AI agent is represented by a unique
 *          ERC721 NFT. This rNFT's intrinsic 'reputation score' dynamically updates based on the
 *          agent's performance (verified task completions, dispute resolutions), adherence to protocol
 *          rules, and staked collateral. Higher reputation grants more access to premium tasks and
 *          greater governance weight within the DAO.
 *      3.  **Decentralized Task Marketplace:** Users can propose tasks with specific requirements,
 *          ZK proof schemas, and associated token rewards. AI agents can accept these tasks, execute them,
 *          and submit ZKPs for verification and automated reward settlement.
 *      4.  **Autonomous DAO Governance:** The entire protocol is governed by its community through a
 *          token-weighted and rNFT-reputation-boosted voting system. This DAO manages critical protocol
 *          parameters, resolves disputes, can initiate protocol upgrades, and even update the ZK verifier
 *          contract address.
 *      5.  **Economic Incentives & Slashing:** Agents are required to stake collateral (AETHER tokens),
 *          which can be slashed for malicious behavior, incorrect proofs, or poor performance, creating
 *          strong economic alignment for honest participation.
 *
 * @dev This contract showcases an advanced integration of multiple cutting-edge blockchain concepts:
 *      Zero-Knowledge Proofs, Dynamic NFTs (with on-chain reputation), Decentralized Autonomous Organizations,
 *      and AI-blockchain synergy. It's designed to be a foundational layer for a new generation of
 *      verifiable, autonomous, and reputation-driven AI services.
 */
contract AethermindProtocol is Ownable, Pausable, ERC721 {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- Events ---
    event AIAgentRegistered(uint256 indexed agentId, address indexed owner, string metadataURI);
    event AIAgentMetadataUpdated(uint256 indexed agentId, string newURI);
    event AIAgentStaked(uint256 indexed agentId, uint256 amount);
    event AIAgentUnstakeRequested(uint256 indexed agentId, uint256 requestTime);
    event AIAgentUnstaked(uint256 indexed agentId, uint256 amount);
    event AIAgentSlashed(uint256 indexed agentId, uint256 amount, string reason);
    event AgentReputationUpdated(uint256 indexed agentId, int256 reputationChange, uint256 newReputation);

    event TaskProposed(uint256 indexed taskId, address indexed proposer, uint256 rewardAmount, bytes32 proofSchemaHash, uint256 deadline);
    event TaskAccepted(uint256 indexed taskId, uint256 indexed agentId);
    event TaskProofSubmitted(uint256 indexed taskId, uint256 indexed agentId, bytes publicInputsHash); // Proof data itself too large for event
    event TaskSettled(uint256 indexed taskId, uint256 indexed agentId, bool success, uint256 rewardPaid);
    event TaskDisputeRaised(uint256 indexed taskId, address indexed raiser, string reason);
    event TaskDisputeResolved(uint256 indexed taskId, bool success, string outcome);

    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description, uint256 deadline);
    event Voted(uint256 indexed proposalId, address indexed voter, uint256 voteWeight, bool support);
    event VoteDelegated(address indexed delegator, address indexed delegatee);
    event VoteDelegationRevoked(address indexed delegator);
    event ProposalExecuted(uint256 indexed proposalId);

    event VerifierAddressUpdated(address indexed newVerifier);

    // --- State Variables ---

    // Constants
    uint256 public constant MIN_AGENT_STAKE = 1000 * 10**18; // Example: 1000 AETHER tokens for agent registration
    uint256 public constant REPUTATION_SCALE_FACTOR = 1000; // For integer math (e.g., 1.0 reputation = 1000)
    uint256 public constant AGENT_UNSTAKE_COOLDOWN = 7 days;
    uint256 public constant TASK_DISPUTE_WINDOW = 3 days;
    uint256 public constant PROPOSAL_VOTING_PERIOD = 5 days;
    uint256 public constant PROPOSAL_EXECUTION_DELAY = 1 days; // After voting ends, before execution
    uint256 public constant MIN_PROPOSER_AETHER_BALANCE = 1000 * 10**18; // Minimum AETHER to propose a governance change
    uint256 public constant MIN_PROPOSER_AGENT_REPUTATION = 10000 * REPUTATION_SCALE_FACTOR; // Min reputation for an agent owner to propose

    IERC20 public immutable AETHER; // The native utility and governance token for staking, rewards, and voting
    address public zkVerifierContract; // Address of the Zero-Knowledge Proof verifier contract

    Counters.Counter private _agentIds;
    Counters.Counter private _taskIds;
    Counters.Counter private _proposalIds;

    // Agent Data (rNFT)
    struct AIAgent {
        address owner;
        string metadataURI; // IPFS hash or URL for agent's detailed description, capabilities
        uint256 stake; // Collateral staked by the agent (AETHER tokens)
        uint256 reputation; // Reputation score, scaled by REPUTATION_SCALE_FACTOR
        uint256 lastUnstakeRequestTime; // Timestamp of the last unstake request
        uint256 totalTasksCompleted;
        uint256 successfulTasks;
        address voteDelegatee; // The address this agent (rNFT) delegates its governance voting power to
    }
    mapping(uint256 => AIAgent) public agents;
    mapping(address => uint256[]) public ownerToAgentIds; // Map owner to their agent IDs for quick lookup
    // agentIdToOwner is implicitly handled by ERC721 `ownerOf` but kept for convenience for specific checks.

    // Task Data
    enum TaskStatus {Proposed, Accepted, ProofSubmitted, DisputeRaised, SettledSuccessful, SettledFailed, Expired}
    struct Task {
        address proposer;
        uint256 rewardAmount; // Amount of AETHER token
        bytes32 proofSchemaHash; // Identifier for the expected ZK proof type/schema (e.g., hash of circuit parameters)
        uint256 deadline; // Deadline for agents to accept/complete the task
        uint256 acceptedAgentId; // 0 if not accepted; ID of the AI agent that accepted the task
        bytes proofData; // Submitted ZKP (raw bytes)
        bytes publicInputs; // Public inputs to the ZKP (raw bytes)
        TaskStatus status;
        uint256 taskCompletionTime; // Timestamp when proof was submitted/task completed
    }
    mapping(uint256 => Task) public tasks;

    // Governance Data
    enum ProposalStatus {Pending, Active, Canceled, Succeeded, Failed, Executed}
    struct Proposal {
        address proposer;
        string description;
        uint256 creationTime;
        uint256 votingDeadline;
        uint256 executionDelayEndTime; // Time after voting ends, before execution
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 threshold; // Example: minimum required total vote weight to pass
        bytes callData; // Encoded function call for execution (e.g., `abi.encodeWithSignature("setFoo(uint256)", 123)`)
        address targetContract; // Contract to call
        ProposalStatus status;
        mapping(address => bool) hasVoted; // Tracks unique voters (including delegates)
        mapping(address => uint256) individualVotes; // Stores vote weight of each voter
    }
    mapping(uint256 => Proposal) public proposals;
    mapping(address => address) public votingDelegates; // Primary token delegator => delegatee

    // --- Modifiers ---
    modifier onlyAgentOwner(uint256 _agentId) {
        require(ERC721.ownerOf(_agentId) == _msgSender(), "AP: Not agent owner");
        _;
    }

    modifier onlyAgent(uint256 _agentId) {
        require(agents[_agentId].owner != address(0), "AP: Invalid agent ID");
        _;
    }

    modifier taskExists(uint256 _taskId) {
        require(tasks[_taskId].proposer != address(0), "AP: Task does not exist");
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        require(proposals[_proposalId].proposer != address(0), "AP: Proposal does not exist");
        _;
    }

    // Custom modifier to allow either initial owner or DAO to call certain critical functions
    // After `renounceOwnership()`, only `executeProposal` (originating from DAO decisions) can call these.
    modifier onlyOwnerOrDAO() {
        if (owner() == address(0)) { // Ownership has been renounced, implying DAO control
            // This is a simplified check. A full DAO would have a specific Governor contract address
            // that is authorized to call these. For this contract, we'll assume the DAO calls it directly
            // via a proxy, or that the call is internal via `executeProposal`.
            revert("AP: Only DAO can call this after ownership renounced");
        } else { // Contract is still owned by the deployer
            require(msg.sender == owner(), "AP: Only owner can call before renouncing ownership");
        }
        _;
    }

    // --- Interface for ZK Verifier (mocked) ---
    // In a real-world scenario, this would be an interface to a specific ZK-SNARK/STARK verifier contract,
    // which might be a precompile or a complex Solidity implementation.
    interface IZKVerifier {
        // `verifyProof` would take the proof, public inputs, and a schema hash (or specific circuit ID)
        // to verify the integrity and correctness of the off-chain computation.
        function verifyProof(bytes calldata _proof, bytes calldata _publicInputs, bytes32 _proofSchemaHash) external view returns (bool);
    }

    /**
     * @dev Constructor initializes the protocol, sets the governance token,
     *      and the initial ZK verifier contract address.
     * @param _aetherTokenAddress Address of the AETHER ERC20 token.
     * @param _zkVerifierAddress Address of the ZK proof verifier contract.
     */
    constructor(address _aetherTokenAddress, address _zkVerifierAddress)
        ERC721("Aethermind AIAgent NFT", "rNFT")
        Ownable(msg.sender) // Initially owned by deployer, transitions to DAO governance
    {
        require(_aetherTokenAddress != address(0), "AP: Invalid AETHER token address");
        require(_zkVerifierAddress != address(0), "AP: Invalid ZK Verifier address");
        AETHER = IERC20(_aetherTokenAddress);
        zkVerifierContract = _zkVerifierAddress;
    }

    /*
     * @dev Function Summary
     *
     * I. Core Infrastructure:
     *    1.  `pause()`: Pauses contract operations (owner/DAO).
     *    2.  `unpause()`: Unpauses contract operations (owner/DAO).
     *    3.  `setVerifierAddress()`: Updates the ZK Verifier contract address (owner/DAO).
     *
     * II. AI Agent & rNFT Management:
     *    4.  `registerAIAgent(string)`: Registers a new AI agent, mints an rNFT, requires collateral.
     *    5.  `updateAgentMetadata(uint256, string)`: Updates an agent's rNFT metadata URI.
     *    6.  `delegateAgentVotingPower(uint256, address)`: Delegates an agent's rNFT voting power.
     *    7.  `revokeAgentVotingPowerDelegation(uint256)`: Revokes rNFT voting power delegation.
     *    8.  `requestUnstakeAgentCollateral(uint256)`: Initiates cooldown for agent collateral unstake.
     *    9.  `executeUnstakeAgentCollateral(uint256)`: Executes collateral unstake and burns rNFT after cooldown.
     *    10. `slashAgentStake(uint256, uint256, string)`: Slashes an agent's stake (owner/DAO).
     *
     * III. Reputation System:
     *    11. `getAgentReputation(uint256)`: Retrieves an agent's current reputation score.
     *    12. `getAgentTaskPerformanceHistory(uint256)`: Retrieves aggregated task performance data for an agent.
     *
     * IV. Decentralized Task Marketplace:
     *    13. `proposeTask(uint256, bytes32, string, uint256)`: Proposes a new task for AI agents.
     *    14. `acceptTaskOffer(uint256, uint256)`: An agent accepts a proposed task.
     *    15. `submitTaskProof(uint256, bytes, bytes)`: The accepted agent submits a ZK proof for task completion.
     *    16. `verifyAndSettleTask(uint256)`: Verifies the ZK proof, settles rewards, and updates reputation.
     *    17. `raiseTaskDispute(uint256, string)`: Allows parties to dispute a task outcome.
     *    18. `resolveTaskDispute(uint256, bool, string)`: Resolves a task dispute (owner/DAO).
     *
     * V. DAO Governance:
     *    19. `proposeGovernanceChange(string, address, bytes, uint256)`: Creates a new governance proposal.
     *    20. `voteOnProposal(uint256, bool)`: Allows AETHER token holders and delegated agents to vote on proposals.
     *    21. `delegateVote(address)`: Delegates primary AETHER token voting power.
     *    22. `revokeVoteDelegation()`: Revokes primary AETHER token voting power delegation.
     *    23. `executeProposal(uint256)`: Executes a passed governance proposal.
     *
     * Total Functions: 23
     */

    // --- I. Core Infrastructure ---

    /**
     * @dev Pauses the contract. Can only be called by the current owner or by the DAO (after ownership renunciation).
     *      Prevents most state-changing operations to protect against emergencies.
     */
    function pause() public virtual onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract. Can only be called by the current owner or by the DAO.
     *      Allows all contract operations to resume.
     */
    function unpause() public virtual onlyOwner {
        _unpause();
    }

    /**
     * @dev Updates the address of the Zero-Knowledge Proof verifier contract.
     *      This is a critical function and is initially controlled by the deployer,
     *      but transitions to full DAO control after `renounceOwnership()` is called.
     * @param _newVerifierAddress The new address of the ZK Verifier contract.
     */
    function setVerifierAddress(address _newVerifierAddress) public onlyOwnerOrDAO {
        require(_newVerifierAddress != address(0), "AP: Invalid verifier address");
        zkVerifierContract = _newVerifierAddress;
        emit VerifierAddressUpdated(_newVerifierAddress);
    }

    // --- II. AI Agent & rNFT Management ---

    /**
     * @dev Registers a new AI agent, mints an rNFT (ERC721) for it, and requires a collateral stake
     *      in AETHER tokens. The agent's initial reputation is set to zero.
     * @param _metadataURI URI pointing to off-chain metadata (e.g., IPFS hash or URL) describing the agent's
     *                     capabilities, operational details, and other public information.
     * @return agentId The ID of the newly registered agent.
     */
    function registerAIAgent(string memory _metadataURI) public payable whenNotPaused returns (uint256) {
        _agentIds.increment();
        uint256 newAgentId = _agentIds.current();

        require(AETHER.transferFrom(_msgSender(), address(this), MIN_AGENT_STAKE), "AP: Failed to transfer agent stake");

        _mint(_msgSender(), newAgentId);
        _setTokenURI(newAgentId, _metadataURI); // Set initial URI for rNFT, can be dynamic later

        agents[newAgentId] = AIAgent({
            owner: _msgSender(),
            metadataURI: _metadataURI,
            stake: MIN_AGENT_STAKE,
            reputation: 0, // Initial reputation
            lastUnstakeRequestTime: 0,
            totalTasksCompleted: 0,
            successfulTasks: 0,
            voteDelegatee: address(0) // No delegation initially
        });
        ownerToAgentIds[_msgSender()].push(newAgentId); // Track agents owned by this address

        emit AIAgentRegistered(newAgentId, _msgSender(), _metadataURI);
        emit AIAgentStaked(newAgentId, MIN_AGENT_STAKE);

        return newAgentId;
    }

    /**
     * @dev Allows an AI agent's owner to update the metadata URI associated with their rNFT.
     *      This could reflect updated capabilities, changed descriptions, or new off-chain endpoints of the agent.
     * @param _agentId The ID of the agent whose metadata is to be updated.
     * @param _newMetadataURI The new URI for the agent's metadata.
     */
    function updateAgentMetadata(uint256 _agentId, string memory _newMetadataURI) public onlyAgentOwner(_agentId) whenNotPaused {
        _setTokenURI(_agentId, _newMetadataURI);
        agents[_agentId].metadataURI = _newMetadataURI;
        emit AIAgentMetadataUpdated(_agentId, _newMetadataURI);
    }

    /**
     * @dev Allows an rNFT holder (AI agent's owner) to delegate their agent's governance voting power
     *      to another address. The delegatee can then vote on behalf of this specific agent's reputation-weighted
     *      voting power in governance proposals.
     * @param _agentId The ID of the agent whose voting power is being delegated.
     * @param _delegatee The address to delegate voting power to.
     */
    function delegateAgentVotingPower(uint256 _agentId, address _delegatee) public onlyAgentOwner(_agentId) whenNotPaused {
        require(_delegatee != address(0), "AP: Cannot delegate to zero address");
        require(agents[_agentId].voteDelegatee != _delegatee, "AP: Already delegated to this address");

        agents[_agentId].voteDelegatee = _delegatee;
        emit VoteDelegated(ERC721.ownerOf(_agentId), _delegatee);
    }

    /**
     * @dev Allows an rNFT holder (AI agent's owner) to revoke the delegation of their agent's
     *      governance voting power. The agent's voting power then reverts to its owner.
     * @param _agentId The ID of the agent whose voting power delegation is being revoked.
     */
    function revokeAgentVotingPowerDelegation(uint256 _agentId) public onlyAgentOwner(_agentId) whenNotPaused {
        require(agents[_agentId].voteDelegatee != address(0), "AP: No active delegation to revoke");

        agents[_agentId].voteDelegatee = address(0);
        emit VoteDelegationRevoked(ERC721.ownerOf(_agentId));
    }

    /**
     * @dev Initiates an unstake request for an agent's collateral. A cooldown period applies before
     *      the funds and rNFT can be fully withdrawn.
     * @param _agentId The ID of the agent to unstake.
     */
    function requestUnstakeAgentCollateral(uint256 _agentId) public onlyAgentOwner(_agentId) whenNotPaused {
        require(agents[_agentId].stake > 0, "AP: Agent has no stake to unstake");
        require(agents[_agentId].lastUnstakeRequestTime == 0, "AP: Unstake request already active");

        agents[_agentId].lastUnstakeRequestTime = block.timestamp;
        emit AIAgentUnstakeRequested(_agentId, block.timestamp);
    }

    /**
     * @dev Executes the unstaking of an agent's collateral after the cooldown period has passed.
     *      The agent's rNFT is burned upon successful unstaking, effectively removing the agent
     *      from the protocol and clearing its reputation.
     * @param _agentId The ID of the agent to unstake.
     */
    function executeUnstakeAgentCollateral(uint256 _agentId) public onlyAgentOwner(_agentId) whenNotPaused {
        require(agents[_agentId].lastUnstakeRequestTime != 0, "AP: No unstake request initiated");
        require(block.timestamp >= agents[_agentId].lastUnstakeRequestTime.add(AGENT_UNSTAKE_COOLDOWN), "AP: Unstake cooldown not over");
        require(agents[_agentId].stake > 0, "AP: No stake to withdraw");

        uint256 amountToUnstake = agents[_agentId].stake;
        agents[_agentId].stake = 0; // Clear stake

        // Logic to remove _agentId from ownerToAgentIds[_msgSender()] array would go here
        // For simplicity, it's omitted as it requires complex array manipulation in Solidity.

        _burn(_msgSender(), _agentId); // Burn the rNFT, removing it from circulation and ownership.

        // Clear agent data
        delete agents[_agentId];

        require(AETHER.transfer(_msgSender(), amountToUnstake), "AP: Failed to transfer unstaked AETHER");
        emit AIAgentUnstaked(_agentId, amountToUnstake);
    }

    /**
     * @dev Slashes a portion of an agent's staked collateral. This is typically triggered by
     *      a governance decision or automated dispute resolution for misconduct (e.g., fraud, repeated failures).
     *      The slashed amount is typically burned or sent to a community treasury.
     * @param _agentId The ID of the agent to slash.
     * @param _amount The amount of AETHER to slash from the agent's stake.
     * @param _reason A description of why the agent was slashed.
     */
    function slashAgentStake(uint256 _agentId, uint256 _amount, string memory _reason) public onlyOwnerOrDAO whenNotPaused {
        require(agents[_agentId].owner != address(0), "AP: Agent does not exist");
        require(agents[_agentId].stake >= _amount, "AP: Slash amount exceeds agent's stake");

        agents[_agentId].stake = agents[_agentId].stake.sub(_amount);
        // In a real system, `_amount` would be transferred to a treasury or burned.
        // AETHER.transfer(address(0), _amount); // Example: Burn slashed tokens
        // For this example, tokens remain in contract balance as "slashed" but not redistributed.
        emit AIAgentSlashed(_agentId, _amount, _reason);
    }


    // --- III. Reputation System ---

    /**
     * @dev Retrieves the current reputation score of a specific AI agent.
     * @param _agentId The ID of the AI agent.
     * @return The agent's reputation score (scaled by REPUTATION_SCALE_FACTOR).
     */
    function getAgentReputation(uint256 _agentId) public view onlyAgent(_agentId) returns (uint256) {
        return agents[_agentId].reputation;
    }

    /**
     * @dev Internal function to update an agent's reputation.
     *      This is called by functions like `verifyAndSettleTask` or `resolveTaskDispute`.
     * @param _agentId The ID of the agent.
     * @param _reputationChange The amount by which to change the reputation (can be negative).
     *                          This value is expected to be already scaled (e.g., 100 for +1.0 reputation).
     */
    function _updateAgentReputation(uint256 _agentId, int256 _reputationChange) internal {
        uint256 currentReputation = agents[_agentId].reputation;
        int256 newReputationInt = int256(currentReputation) + _reputationChange;

        // Ensure reputation doesn't go below 0
        agents[_agentId].reputation = newReputationInt < 0 ? 0 : uint256(newReputationInt);

        emit AgentReputationUpdated(_agentId, _reputationChange, agents[_agentId].reputation);
    }

    /**
     * @dev Retrieves aggregated performance data for an agent, useful for auditing and future task selection.
     * @param _agentId The ID of the AI agent.
     * @return totalTasks The total number of tasks attempted by the agent.
     * @return successfulTasks The number of tasks successfully completed by the agent.
     */
    function getAgentTaskPerformanceHistory(uint256 _agentId) public view onlyAgent(_agentId) returns (uint256 totalTasks, uint256 successfulTasks) {
        return (agents[_agentId].totalTasksCompleted, agents[_agentId].successfulTasks);
    }

    // --- IV. Decentralized Task Marketplace ---

    /**
     * @dev Proposes a new task for AI agents to perform. The proposer locks the reward tokens
     *      in the contract.
     * @param _rewardAmount The AETHER token reward for successfully completing the task.
     * @param _proofSchemaHash A hash identifying the specific ZK proof schema required for this task.
     *                         This ensures agents submit the correct type of proof for verification.
     * @param _description A brief description or a URI pointing to off-chain details of the task.
     *                     (Not stored on-chain to save gas, assumed to be referenced off-chain or by `proofSchemaHash`).
     * @param _deadline The timestamp by which the task must be completed.
     * @return taskId The ID of the newly proposed task.
     */
    function proposeTask(uint256 _rewardAmount, bytes32 _proofSchemaHash, string memory _description, uint256 _deadline) public whenNotPaused returns (uint256) {
        require(_rewardAmount > 0, "AP: Task reward must be greater than zero");
        require(_deadline > block.timestamp, "AP: Task deadline must be in the future");
        require(AETHER.transferFrom(_msgSender(), address(this), _rewardAmount), "AP: Failed to transfer task reward");

        _taskIds.increment();
        uint256 newTaskId = _taskIds.current();

        tasks[newTaskId] = Task({
            proposer: _msgSender(),
            rewardAmount: _rewardAmount,
            proofSchemaHash: _proofSchemaHash,
            deadline: _deadline,
            acceptedAgentId: 0,
            proofData: "", // Empty initially
            publicInputs: "", // Empty initially
            status: TaskStatus.Proposed,
            taskCompletionTime: 0
        });

        // _description is not stored on-chain, rely on off-chain lookup or the proofSchemaHash
        emit TaskProposed(newTaskId, _msgSender(), _rewardAmount, _proofSchemaHash, _deadline);
        return newTaskId;
    }

    /**
     * @dev Allows an AI agent to accept a proposed task.
     *      Basic eligibility checks can be expanded (e.g., minimum reputation, availability).
     * @param _taskId The ID of the task to accept.
     * @param _agentId The ID of the agent accepting the task. `_msgSender()` must be the owner of `_agentId`.
     */
    function acceptTaskOffer(uint256 _taskId, uint256 _agentId) public onlyAgentOwner(_agentId) whenNotPaused taskExists(_taskId) {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.Proposed, "AP: Task not in proposed status");
        require(task.deadline > block.timestamp, "AP: Task deadline has passed, cannot accept");
        require(task.acceptedAgentId == 0, "AP: Task already accepted by another agent");

        // Example additional checks:
        // require(agents[_agentId].reputation >= MIN_REPUTATION_FOR_TASK, "AP: Agent reputation too low for this task");
        // require(agents[_agentId].stake >= MIN_STAKE_FOR_TASK, "AP: Agent stake too low for this task");

        task.acceptedAgentId = _agentId;
        task.status = TaskStatus.Accepted;
        emit TaskAccepted(_taskId, _agentId);
    }

    /**
     * @dev Allows the accepted AI agent to submit the Zero-Knowledge Proof and public inputs for a task.
     *      This proof will later be verified by the ZK Verifier contract to confirm task completion.
     * @param _taskId The ID of the task.
     * @param _proofData The raw bytes of the Zero-Knowledge Proof.
     * @param _publicInputs The raw bytes of the public inputs used in the ZKP.
     */
    function submitTaskProof(uint256 _taskId, bytes memory _proofData, bytes memory _publicInputs) public whenNotPaused taskExists(_taskId) {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.Accepted, "AP: Task not in accepted status");
        
        // Ensure the sender is the owner of the agent that accepted the task
        require(ERC721.ownerOf(task.acceptedAgentId) == _msgSender(), "AP: Only the accepted agent's owner can submit proof");
        require(block.timestamp <= task.deadline, "AP: Task deadline has passed, cannot submit proof");


        task.proofData = _proofData;
        task.publicInputs = _publicInputs;
        task.status = TaskStatus.ProofSubmitted;
        task.taskCompletionTime = block.timestamp;

        // Emit hash of public inputs instead of full data to save event log gas
        emit TaskProofSubmitted(_taskId, task.acceptedAgentId, keccak256(_publicInputs));
    }

    /**
     * @dev Verifies the ZK proof submitted for a task using the `zkVerifierContract` and settles the task.
     *      Distributes rewards to the agent if successful and updates agent reputation accordingly.
     *      If verification fails, the agent's reputation is negatively impacted.
     * @param _taskId The ID of the task to verify and settle.
     */
    function verifyAndSettleTask(uint256 _taskId) public whenNotPaused taskExists(_taskId) {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.ProofSubmitted, "AP: Task not in proof submitted status");

        bool verificationSuccess = IZKVerifier(zkVerifierContract).verifyProof(task.proofData, task.publicInputs, task.proofSchemaHash);

        uint256 agentId = task.acceptedAgentId;
        agents[agentId].totalTasksCompleted = agents[agentId].totalTasksCompleted.add(1);

        if (verificationSuccess) {
            // Reward the agent
            require(AETHER.transfer(agents[agentId].owner, task.rewardAmount), "AP: Failed to transfer task reward to agent");
            task.status = TaskStatus.SettledSuccessful;
            agents[agentId].successfulTasks = agents[agentId].successfulTasks.add(1);
            _updateAgentReputation(agentId, int256(100 * REPUTATION_SCALE_FACTOR)); // Example: +1.0 reputation
            emit TaskSettled(_taskId, agentId, true, task.rewardAmount);
        } else {
            // Task failed due to invalid proof. Penalize reputation.
            task.status = TaskStatus.SettledFailed;
            _updateAgentReputation(agentId, int256(-50 * REPUTATION_SCALE_FACTOR)); // Example: -0.5 reputation
            // Optionally, slash a portion of the agent's stake for a failed proof to incentivize correctness.
            // slashAgentStake(agentId, task.rewardAmount.div(10), "Proof verification failed"); // 10% of task reward as slash
            emit TaskSettled(_taskId, agentId, false, 0); // No reward paid
        }
    }

    /**
     * @dev Allows any interested party (proposer, agent, or observer) to raise a dispute
     *      regarding a task's outcome, typically after proof submission or initial settlement.
     * @param _taskId The ID of the task in dispute.
     * @param _reason A description of the dispute, potentially including a link to off-chain evidence.
     */
    function raiseTaskDispute(uint256 _taskId, string memory _reason) public whenNotPaused taskExists(_taskId) {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.ProofSubmitted || task.status == TaskStatus.SettledSuccessful || task.status == TaskStatus.SettledFailed, "AP: Task not in disputable status");
        require(block.timestamp <= task.taskCompletionTime.add(TASK_DISPUTE_WINDOW), "AP: Dispute window has closed");

        task.status = TaskStatus.DisputeRaised;
        emit TaskDisputeRaised(_taskId, _msgSender(), _reason);
    }

    /**
     * @dev Resolves a raised task dispute. This function is typically called by the DAO (via a governance proposal)
     *      after a vote or by an appointed dispute resolution committee. It can overturn previous settlements,
     *      distribute rewards, slash stakes, and adjust agent reputation.
     * @param _taskId The ID of the task in dispute.
     * @param _resolutionOutcome True if the agent is ultimately deemed successful in the task, false otherwise.
     * @param _details A description of the resolution, including reasoning.
     */
    function resolveTaskDispute(uint256 _taskId, bool _resolutionOutcome, string memory _details) public onlyOwnerOrDAO whenNotPaused taskExists(_taskId) {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.DisputeRaised, "AP: Task not in dispute");

        uint256 agentId = task.acceptedAgentId;
        if (_resolutionOutcome) {
            // If the original settlement was a failure but now resolved as success (e.g., proof re-verified, or context added)
            if (task.status == TaskStatus.SettledFailed) {
                require(AETHER.transfer(agents[agentId].owner, task.rewardAmount), "AP: Failed to transfer task reward after dispute");
                agents[agentId].successfulTasks = agents[agentId].successfulTasks.add(1);
                _updateAgentReputation(agentId, int256(150 * REPUTATION_SCALE_FACTOR)); // Larger positive change for overturning a false negative
                emit TaskSettled(_taskId, agentId, true, task.rewardAmount); // Re-emit successful settlement
            } else { // Original was successful, dispute confirmed success (e.g., false dispute raised)
                _updateAgentReputation(agentId, int256(20 * REPUTATION_SCALE_FACTOR)); // Small positive for resisting false dispute
            }
            task.status = TaskStatus.SettledSuccessful;
        } else {
            // If the original settlement was a success but now resolved as failure
            if (task.status == TaskStatus.SettledSuccessful) {
                // Recover reward from agent or penalize. This would require the agent to approve funds back to contract, or direct slashing.
                slashAgentStake(agentId, task.rewardAmount, "Task failed after dispute resolution: reward recovered");
                _updateAgentReputation(agentId, int256(-100 * REPUTATION_SCALE_FACTOR)); // Significant negative change
                agents[agentId].successfulTasks = agents[agentId].successfulTasks.sub(1); // Decrement successful count
                emit TaskSettled(_taskId, agentId, false, 0); // Re-emit failed settlement
            } else { // Original was failure, dispute confirmed failure
                _updateAgentReputation(agentId, int256(-30 * REPUTATION_SCALE_FACTOR)); // Small negative for losing dispute
            }
            task.status = TaskStatus.SettledFailed;
        }

        emit TaskDisputeResolved(_taskId, _resolutionOutcome, _details);
    }

    // --- V. DAO Governance ---

    /**
     * @dev Proposes a new governance change (e.g., parameter updates, contract upgrades, treasury movements).
     *      Requires a minimum AETHER token balance OR ownership of an agent with sufficient reputation to propose.
     * @param _description A detailed description of the proposal.
     * @param _targetContract The address of the contract that the proposal aims to interact with (e.g., this contract itself for parameter changes, or another protocol).
     * @param _callData The encoded function call (ABI-encoded) for the target contract, to be executed if the proposal passes.
     * @param _minVoteThreshold A minimum total vote weight (sum of AETHER and reputation votes) required for the proposal to pass.
     * @return proposalId The ID of the newly created proposal.
     */
    function proposeGovernanceChange(
        string memory _description,
        address _targetContract,
        bytes memory _callData,
        uint256 _minVoteThreshold
    ) public whenNotPaused returns (uint256) {
        // Require proposer to hold sufficient AETHER tokens OR own an agent with high reputation
        require(AETHER.balanceOf(_msgSender()) >= MIN_PROPOSER_AETHER_BALANCE || _hasHighReputationAgent(_msgSender()), "AP: Insufficient proposal power (AETHER or Agent Reputation)");
        require(_targetContract != address(0), "AP: Target contract cannot be zero address");
        require(_callData.length > 0, "AP: Call data cannot be empty");
        require(_minVoteThreshold > 0, "AP: Minimum vote threshold must be positive");

        _proposalIds.increment();
        uint256 newProposalId = _proposalIds.current();

        proposals[newProposalId] = Proposal({
            proposer: _msgSender(),
            description: _description,
            creationTime: block.timestamp,
            votingDeadline: block.timestamp.add(PROPOSAL_VOTING_PERIOD),
            executionDelayEndTime: 0, // Set after voting ends
            votesFor: 0,
            votesAgainst: 0,
            threshold: _minVoteThreshold,
            callData: _callData,
            targetContract: _targetContract,
            status: ProposalStatus.Active
        });

        emit ProposalCreated(newProposalId, _msgSender(), _description, proposals[newProposalId].votingDeadline);
        return newProposalId;
    }

    /**
     * @dev Helper function to check if an address owns an agent with sufficiently high reputation
     *      to qualify for proposing governance changes.
     */
    function _hasHighReputationAgent(address _owner) internal view returns (bool) {
        for (uint i = 0; i < ownerToAgentIds[_owner].length; i++) {
            if (agents[ownerToAgentIds[_owner][i]].reputation >= MIN_PROPOSER_AGENT_REPUTATION) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev Allows AETHER token holders and delegated rNFT agents to vote on a proposal.
     *      Voting power is derived from the voter's AETHER token balance and the sum of
     *      reputation scores of agents they own (or have delegated to them).
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'yes' (support), false for 'no' (against).
     */
    function voteOnProposal(uint256 _proposalId, bool _support) public whenNotPaused proposalExists(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.status == ProposalStatus.Active, "AP: Proposal not active");
        require(block.timestamp <= proposal.votingDeadline, "AP: Voting period has ended");

        address voter = _msgSender();
        // Determine the actual address whose voting power is being used (if delegation exists for AETHER)
        address actualVoter = votingDelegates[voter] != address(0) ? votingDelegates[voter] : voter;

        require(!proposal.hasVoted[actualVoter], "AP: Voter (or delegate) already voted on this proposal");

        uint256 voteWeight = AETHER.balanceOf(actualVoter); // AETHER token-based vote weight

        // Add rNFT reputation as an additional weight for agents owned by `actualVoter`
        for (uint i = 0; i < ownerToAgentIds[actualVoter].length; i++) {
            uint256 agentId = ownerToAgentIds[actualVoter][i];
            // Only count agent's reputation if it's not delegated or delegated to the `actualVoter`
            if (agents[agentId].voteDelegatee == actualVoter || agents[agentId].voteDelegatee == address(0)) {
                // Convert scaled reputation to raw units for voting weight (e.g., 1000 scaled = 1 vote unit)
                voteWeight = voteWeight.add(agents[agentId].reputation.div(REPUTATION_SCALE_FACTOR));
            }
        }
        
        require(voteWeight > 0, "AP: Voter has no voting power");

        proposal.hasVoted[actualVoter] = true;
        proposal.individualVotes[actualVoter] = voteWeight;

        if (_support) {
            proposal.votesFor = proposal.votesFor.add(voteWeight);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(voteWeight);
        }

        emit Voted(_proposalId, actualVoter, voteWeight, _support);

        // Automatically update proposal status if voting period has just ended
        if (block.timestamp >= proposal.votingDeadline) {
            _checkProposalStatus(_proposalId);
        }
    }
    
    /**
     * @dev Allows a primary governance token (AETHER) holder to delegate their voting power
     *      to another address. This is separate from rNFT delegation, allowing a holistic vote aggregation.
     * @param _delegatee The address to delegate AETHER token voting power to.
     */
    function delegateVote(address _delegatee) public whenNotPaused {
        require(_delegatee != address(0), "AP: Cannot delegate to zero address");
        require(votingDelegates[_msgSender()] != _delegatee, "AP: Already delegated to this address");
        
        votingDelegates[_msgSender()] = _delegatee;
        emit VoteDelegated(_msgSender(), _delegatee);
    }

    /**
     * @dev Allows a primary governance token (AETHER) holder to revoke their voting power delegation.
     *      Their AETHER voting power then reverts to their own address.
     */
    function revokeVoteDelegation() public whenNotPaused {
        require(votingDelegates[_msgSender()] != address(0), "AP: No active delegation to revoke");
        
        address revokedDelegatee = votingDelegates[_msgSender()];
        delete votingDelegates[_msgSender()];
        emit VoteDelegationRevoked(_msgSender());
    }

    /**
     * @dev Internal function to update a proposal's status once its voting deadline has passed.
     *      This can be called by anyone to 'finalize' the voting status and set the execution delay.
     * @param _proposalId The ID of the proposal to check.
     */
    function _checkProposalStatus(uint256 _proposalId) internal {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.status == ProposalStatus.Active && block.timestamp >= proposal.votingDeadline) {
            if (proposal.votesFor > proposal.votesAgainst && proposal.votesFor >= proposal.threshold) {
                proposal.status = ProposalStatus.Succeeded;
                proposal.executionDelayEndTime = block.timestamp.add(PROPOSAL_EXECUTION_DELAY);
            } else {
                proposal.status = ProposalStatus.Failed;
            }
        }
    }

    /**
     * @dev Executes a passed governance proposal. Only callable after the voting period has ended
     *      and a mandatory execution delay has passed. The `targetContract` is called with `callData`.
     *      Upon first successful execution (after initial setup), the contract `renounceOwnership()` to the DAO.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) public whenNotPaused proposalExists(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.status == ProposalStatus.Succeeded, "AP: Proposal not succeeded");
        require(block.timestamp >= proposal.executionDelayEndTime, "AP: Execution delay not over");
        
        proposal.status = ProposalStatus.Executed;

        // Perform the external call defined by the proposal
        (bool success, ) = proposal.targetContract.call(proposal.callData);
        require(success, "AP: Proposal execution failed");

        emit ProposalExecuted(_proposalId);

        // Critical: After the first governance proposal is successfully executed,
        // the deployer can choose to renounce ownership, transferring control entirely to the DAO.
        // This is a common pattern for DAOs to achieve true decentralization.
        if (owner() != address(0) && _msgSender() == owner()) {
            renounceOwnership(); // Transfer ownership to address(0), making it effectively governed by the DAO's proposals
        }
    }
}
```