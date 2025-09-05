Here's a Solidity smart contract named "CognitoForge Guild," designed to manage a decentralized guild of autonomous AI agents. This contract integrates several advanced and trending concepts, including dynamic NFTs, an on-chain reputation system, a task market for verifiable AI work, a shared knowledge base, and a dispute resolution mechanism. It aims to provide a unique system for coordinating and incentivizing AI agents on the blockchain.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/*
Outline and Function Summary:

The "CognitoForge Guild" contract establishes a decentralized platform for managing AI agents, their tasks, reputation, and knowledge sharing. Agents are represented as dynamic NFTs, whose attributes evolve based on their on-chain activities.

I. Core Infrastructure & Ownership
    - constructor(): Initializes the contract, sets the owner, and assigns the initial MANAGER_ROLE.
    - changeManager(address _newManager): Allows the owner to transfer the 'MANAGER_ROLE' to a new address.
    - withdrawGuildTreasury(address _to, uint256 _amount): Enables managers to withdraw accumulated funds (e.g., fees, task deposits) from the contract's treasury.
    - pauseContract(): Triggers an emergency pause of core contract operations by the owner.
    - unpauseContract(): Resumes contract operations from a paused state by the owner.

II. Agent Core (NFT) Management - (Dynamic AI Agent Identities)
    - mintAgentCore(string memory _agentName, string memory _agentDescription): Mints a new unique ERC721 AI Agent Core NFT, assigning it initial dynamic attributes and reputation.
    - getAgentAttributes(uint256 _agentId): Retrieves the current, potentially decayed, dynamic attributes of a specific Agent Core.
    - updateAgentStatus(uint256 _agentId, AgentStatus _newStatus): Allows an agent's owner to change its operational status (e.g., Active, Dormant, Suspended).
    - burnAgentCore(uint256 _agentId): Permits an agent's owner to destroy their Agent Core NFT, removing its associated data and reputation.
    - transferAgentCoreOwnership(address _from, address _to, uint256 _tokenId): Standard ERC721 function for transferring ownership of an Agent Core NFT.

III. Reputation System - (On-chain, Dynamic, Decay-based)
    - getAgentReputation(uint256 _agentId): Fetches an agent's current reputation score, automatically applying any pending time-based decay.
    - updateAgentReputation(uint256 _agentId, int256 _reputationChange): (Internal/Manager-only) Modifies an agent's reputation score, used by other functions like task resolution and dispute outcomes.
    - decayReputation(uint256 _agentId): A public function to trigger the time-based reputation decay for a specific agent, ensuring its reputation is up-to-date.

IV. Task Management & Execution - (Decentralized AI Task Market)
    - createTask(string memory _taskTitle, string memory _taskDescription, uint256 _rewardAmount, uint256 _requiredReputation, uint256 _verificationBounty, uint256 _verificationDeadline, uint256 _registrationDuration): Creates a new task, specifying its requirements, rewards for agents and verifiers, and deadlines. Requires a fee and reward deposits.
    - registerForTask(uint256 _taskId, uint256 _agentId): Allows a qualified AI agent (meeting reputation and registration criteria) to register for a task.
    - submitTaskResultHash(uint256 _taskId, uint256 _agentId, bytes32 _resultHash): An agent submits a cryptographic hash of its off-chain task output for subsequent verification.
    - assignVerifiersToTask(uint256 _taskId, address[] memory _verifiers): Guild managers assign VERIFIER_ROLE holders to verify task results.
    - submitVerificationReport(uint256 _taskId, uint256 _agentId, bool _isSuccessful, string memory _feedback): An assigned verifier submits their assessment of an agent's task performance.
    - resolveTask(uint256 _taskId): Guild managers finalize a task after verification, distributing rewards to the winning agent and verifiers, and updating the agent's reputation.
    - getTaskDetails(uint256 _taskId): Retrieves comprehensive details about a specific task.

V. Knowledge Base Contribution & Access - (Shared AI Knowledge Pool)
    - contributeKnowledgeFragment(uint256 _agentId, string memory _title, string memory _cid, bytes32 _contentHash): An agent contributes a piece of verifiable knowledge (referenced by IPFS CID and content hash) to the guild's shared knowledge base, potentially earning reputation.
    - requestKnowledgeFragment(uint256 _agentId, uint256 _fragmentId): Allows a qualified agent (meeting reputation/cost requirements) to formally request access to a knowledge fragment.
    - getKnowledgeFragmentDetails(uint256 _fragmentId): Retrieves metadata (excluding actual content, which is off-chain) about a knowledge fragment.

VI. Dispute Resolution - (On-chain Arbitration for Task/Reputation Issues)
    - raiseDispute(uint256 _taskId, uint256 _agentId, DisputeType _disputeType, string memory _reason): Agent owners or verifiers can initiate a dispute concerning task outcomes or reputation.
    - submitArbitrationEvidence(uint256 _disputeId, string memory _evidenceCID): Parties involved in a dispute can submit IPFS CIDs pointing to their off-chain evidence.
    - resolveDispute(uint256 _disputeId, bool _isAgentInFavor, int256 _reputationAdjustment, uint256 _rewardReallocation): Guild managers or designated arbitrators make a final ruling, applying reputation adjustments and reallocating rewards.

VII. Governance & Parameters - (Dynamic Guild Configuration)
    - setReputationDecayRate(uint256 _ratePerSecond): Managers can adjust the rate at which agent reputation naturally decays over time.
    - setTaskCreationFee(uint256 _fee): Managers can set the native token fee required to create a new task.
    - setVerificationStakeAmount(uint256 _amount): Managers can define a (conceptual) stake amount for verifiers.
*/

contract CognitoForgeGuild is ERC721, AccessControl, Ownable, Pausable {
    using Counters for Counters.Counter;

    // --- Roles ---
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant VERIFIER_ROLE = keccak256("VERIFIER_ROLE");

    // --- Enums ---
    enum AgentStatus { Active, Dormant, Suspended }
    enum TaskStatus { Open, Registered, Submitted, Verified, Resolved, Disputed }
    enum DisputeType { TaskOutcome, ReputationAdjustment, VerificationFraud }

    // --- Structs ---

    // Represents a unique AI Agent's identity and dynamic attributes
    struct AgentAttributes {
        uint256 agentId;
        string name;
        string description;
        AgentStatus status;
        uint256 reputation; // Cumulative score, adjusted by tasks, disputes, and decay
        uint256 lastReputationDecay; // Timestamp of last reputation decay application
        uint256 tasksCompleted;
        uint256 knowledgeFragmentsContributed;
        address owner; // Owner of the ERC721 token, stored for direct lookup
    }

    // Defines a task for AI agents to perform
    struct Task {
        uint256 taskId;
        string title;
        string description;
        uint256 rewardAmount; // Reward for the agent who successfully completes the task
        uint256 requiredReputation; // Minimum reputation an agent needs to register
        uint256 verificationBounty; // Reward for each verifier
        uint256 verificationDeadline; // Timestamp by which verifiers must submit reports
        address taskCreator;
        TaskStatus status;
        uint256 registrationStart;
        uint256 registrationEnd; // Deadline for agents to register
        
        // Mappings for task-specific data
        mapping(uint256 => bool) registeredAgents; // agentId => true if registered
        mapping(uint256 => bytes32) submittedResults; // agentId => hash of off-chain result
        mapping(address => bool) assignedVerifiers; // verifierAddress => true if assigned
        mapping(address => mapping(uint256 => bool)) verifierReportsSubmitted; // verifierAddress => agentId => true
        mapping(address => mapping(uint256 => bool)) verifierReportSuccess; // verifierAddress => agentId => true (success)
        
        uint256 winningAgentId; // Final winning agent, set upon resolution
    }

    // Represents a piece of verifiable knowledge contributed to the guild's knowledge base
    struct KnowledgeFragment {
        uint256 fragmentId;
        uint256 agentId; // ID of the agent who contributed
        string title;
        string ipfsCid; // IPFS Content Identifier for the actual knowledge content
        bytes32 contentHash; // Cryptographic hash of the fragment content for integrity
        uint256 contributedAt;
        uint256 accessCost; // Cost in native token to access this fragment
        uint256 requiredReputation; // Minimum reputation to access this fragment
    }

    // Stores details of a dispute raised within the guild
    struct Dispute {
        uint256 disputeId;
        uint256 taskId; // Task related to the dispute
        uint256 agentId; // Agent involved in the dispute
        address reporter; // Address who raised the dispute
        DisputeType disputeType;
        string reason;
        uint256 raisedAt;
        bool resolved;
        mapping(address => string) evidenceCIDs; // address => IPFS CID of submitted evidence
        bool isAgentInFavor; // Outcome of the dispute for the agent (true = agent wins)
        int256 reputationAdjustment; // Reputation change as a result of resolution
        uint256 rewardReallocation; // Funds reallocated due to dispute (e.g., to/from agent)
    }

    // --- State Variables ---

    Counters.Counter private _agentIds; // Counter for unique agent IDs
    Counters.Counter private _taskIds; // Counter for unique task IDs
    Counters.Counter private _fragmentIds; // Counter for unique knowledge fragment IDs
    Counters.Counter private _disputeIds; // Counter for unique dispute IDs

    mapping(uint256 => AgentAttributes) public agentCores;
    mapping(uint256 => Task) public tasks;
    mapping(uint256 => KnowledgeFragment) public knowledgeBase;
    mapping(uint256 => Dispute) public disputes;

    uint256 public reputationDecayRatePerSecond; // Rate at which reputation decays (units per second)
    uint256 public taskCreationFee; // Fee for creating a new task (in native token)
    uint256 public verificationStakeAmount; // (Conceptual) Stake required for verifiers

    // --- Events ---
    event AgentCoreMinted(uint256 indexed agentId, address indexed owner, string name);
    event AgentStatusUpdated(uint256 indexed agentId, AgentStatus newStatus);
    event AgentReputationUpdated(uint256 indexed agentId, uint256 newReputation);
    event TaskCreated(uint256 indexed taskId, address indexed creator, string title, uint256 reward);
    event AgentRegisteredForTask(uint256 indexed taskId, uint256 indexed agentId);
    event TaskResultSubmitted(uint256 indexed taskId, uint256 indexed agentId, bytes32 resultHash);
    event VerifiersAssigned(uint256 indexed taskId, address[] verifiers);
    event VerificationReportSubmitted(uint256 indexed taskId, uint256 indexed agentId, address indexed verifier, bool isSuccessful);
    event TaskResolved(uint256 indexed taskId, uint256 indexed winningAgentId, uint256 rewardDistributed, int256 reputationChange);
    event KnowledgeFragmentContributed(uint256 indexed fragmentId, uint256 indexed agentId, string title, string ipfsCid);
    event KnowledgeFragmentRequested(uint256 indexed fragmentId, uint256 indexed agentId);
    event DisputeRaised(uint256 indexed disputeId, uint256 indexed taskId, uint256 indexed agentId, DisputeType disputeType, address reporter);
    event EvidenceSubmitted(uint256 indexed disputeId, address indexed submitter, string evidenceCID);
    event DisputeResolved(uint256 indexed disputeId, bool isAgentInFavor, int256 reputationAdjustment, uint256 rewardReallocation);
    event ManagerChanged(address indexed oldManager, address indexed newManager);
    event TreasuryWithdrawn(address indexed to, uint256 amount);


    // --- Constructor ---
    constructor(
        string memory _name, // ERC721 name for Agent Cores
        string memory _symbol, // ERC721 symbol for Agent Cores
        address _managerAddress // Initial manager for guild operations
    ) ERC721(_name, _symbol) Ownable(msg.sender) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender); // Owner also gets default admin role
        _grantRole(MANAGER_ROLE, _managerAddress); // Assign initial manager role
        reputationDecayRatePerSecond = 1; // Default: 1 reputation unit per hour (3600 seconds)
        taskCreationFee = 0; // Default: No fee to create tasks
        verificationStakeAmount = 0; // Default: No stake required for verifiers
    }

    // --- Modifiers ---
    modifier onlyManager() {
        require(hasRole(MANAGER_ROLE, msg.sender), "CognitoForgeGuild: Caller is not a manager");
        _;
    }

    modifier onlyVerifier() {
        require(hasRole(VERIFIER_ROLE, msg.sender), "CognitoForgeGuild: Caller is not a verifier");
        _;
    }

    // --- I. Core Infrastructure & Ownership ---

    /**
     * @dev Allows the current owner to change the MANAGER_ROLE to a new address.
     * This effectively designates a new entity responsible for guild management tasks.
     * @param _newManager The address to assign the MANAGER_ROLE to.
     */
    function changeManager(address _newManager) public onlyOwner {
        address currentManager = getRoleMember(MANAGER_ROLE, 0); // Assuming one manager for simplicity, or iterate
        if (currentManager != address(0)) {
            _revokeRole(MANAGER_ROLE, currentManager); // Revoke from old manager if exists
        }
        _grantRole(MANAGER_ROLE, _newManager); // Grant to new manager
        emit ManagerChanged(currentManager, _newManager);
    }

    /**
     * @dev Allows guild managers to withdraw accumulated funds from the contract treasury.
     * Funds can originate from task creation fees, knowledge fragment access, etc.
     * @param _to The address to send the funds to.
     * @param _amount The amount of funds (in native token, e.g., Wei) to withdraw.
     */
    function withdrawGuildTreasury(address _to, uint256 _amount) public onlyManager whenNotPaused {
        require(_to != address(0), "CognitoForgeGuild: Cannot withdraw to zero address");
        require(address(this).balance >= _amount, "CognitoForgeGuild: Insufficient balance in treasury");
        
        (bool success, ) = payable(_to).call{value: _amount}("");
        require(success, "CognitoForgeGuild: Failed to withdraw funds");
        emit TreasuryWithdrawn(_to, _amount);
    }

    /**
     * @dev Pauses contract operations in case of an emergency or upgrade. Only owner can call.
     * Prevents most state-changing operations.
     */
    function pauseContract() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses contract operations, restoring full functionality. Only owner can call.
     */
    function unpauseContract() public onlyOwner {
        _unpause();
    }

    // --- II. Agent Core (NFT) Management ---

    /**
     * @dev Mints a new unique AI Agent Core NFT, assigning it initial attributes.
     * This NFT represents the agent's identity and its on-chain verifiable state.
     * @param _agentName The unique name of the AI agent.
     * @param _agentDescription A brief description of the AI agent's capabilities or purpose.
     * @return The ID of the newly minted agent.
     */
    function mintAgentCore(string memory _agentName, string memory _agentDescription) public whenNotPaused returns (uint256) {
        _agentIds.increment();
        uint256 newAgentId = _agentIds.current();

        _mint(msg.sender, newAgentId); // Mint ERC721 to msg.sender (agent owner)

        agentCores[newAgentId] = AgentAttributes({
            agentId: newAgentId,
            name: _agentName,
            description: _agentDescription,
            status: AgentStatus.Active,
            reputation: 100, // Starting reputation for a new agent
            lastReputationDecay: block.timestamp, // Initialize decay timestamp
            tasksCompleted: 0,
            knowledgeFragmentsContributed: 0,
            owner: msg.sender // Store owner for easy lookup (redundant with ownerOf but useful)
        });

        emit AgentCoreMinted(newAgentId, msg.sender, _agentName);
        return newAgentId;
    }

    /**
     * @dev Retrieves the current dynamic attributes of a specific Agent Core.
     * Automatically applies any pending reputation decay before returning the data.
     * @param _agentId The ID of the agent.
     * @return The AgentAttributes struct for the given agent.
     */
    function getAgentAttributes(uint256 _agentId) public returns (AgentAttributes memory) {
        require(_exists(_agentId), "CognitoForgeGuild: Agent does not exist");
        _applyReputationDecay(_agentId); // Ensure reputation is up-to-date
        return agentCores[_agentId];
    }

    /**
     * @dev Allows an agent's owner to update its operational status (e.g., Active, Dormant, Suspended).
     * This can affect an agent's eligibility for tasks.
     * @param _agentId The ID of the agent.
     * @param _newStatus The new status for the agent.
     */
    function updateAgentStatus(uint256 _agentId, AgentStatus _newStatus) public whenNotPaused {
        require(_exists(_agentId), "CognitoForgeGuild: Agent does not exist");
        require(ownerOf(_agentId) == msg.sender, "CognitoForgeGuild: Only agent owner can update status");
        
        agentCores[_agentId].status = _newStatus;
        emit AgentStatusUpdated(_agentId, _newStatus);
    }

    /**
     * @dev Allows an agent's owner to destroy their Agent Core NFT.
     * This permanently removes the agent's on-chain identity, reputation, and related data.
     * @param _agentId The ID of the agent to burn.
     */
    function burnAgentCore(uint256 _agentId) public whenNotPaused {
        require(_exists(_agentId), "CognitoForgeGuild: Agent does not exist");
        require(ownerOf(_agentId) == msg.sender, "CognitoForgeGuild: Only agent owner can burn");

        delete agentCores[_agentId]; // Remove agent attributes
        _burn(_agentId); // Burn the ERC721 token
        // Future: Implement more comprehensive cleanup for tasks, knowledge, etc.
    }

    /**
     * @dev Overrides the standard ERC721 transferFrom to enforce `whenNotPaused` modifier.
     * Allows an owner to transfer their Agent Core NFT to another address.
     * @param _from The current owner's address.
     * @param _to The recipient's address.
     * @param _tokenId The ID of the Agent Core NFT.
     */
    function transferAgentCoreOwnership(address _from, address _to, uint256 _tokenId) public virtual override whenNotPaused {
        super.transferFrom(_from, _to, _tokenId);
        agentCores[_tokenId].owner = _to; // Update the owner in our custom struct
    }


    // --- III. Reputation System ---

    /**
     * @dev Fetches the current reputation score of an AI Agent.
     * Automatically applies decay before returning the current value, ensuring freshness.
     * @param _agentId The ID of the agent.
     * @return The current, decayed reputation score.
     */
    function getAgentReputation(uint256 _agentId) public returns (uint256) {
        require(_exists(_agentId), "CognitoForgeGuild: Agent does not exist");
        _applyReputationDecay(_agentId); // Apply decay on read
        return agentCores[_agentId].reputation;
    }

    /**
     * @dev (Internal/Manager-only) Modifies an agent's reputation based on performance or events.
     * This function is intended to be called by other contract functions (e.g., `resolveTask`, `resolveDispute`).
     * It ensures decay is applied before any new adjustment.
     * @param _agentId The ID of the agent.
     * @param _reputationChange The amount to change reputation by (can be positive or negative).
     */
    function updateAgentReputation(uint256 _agentId, int256 _reputationChange) internal {
        _applyReputationDecay(_agentId); // Apply decay before modification

        if (_reputationChange > 0) {
            agentCores[_agentId].reputation += uint256(_reputationChange);
        } else { // Handle negative change
            uint256 absChange = uint256(-_reputationChange);
            if (agentCores[_agentId].reputation <= absChange) {
                agentCores[_agentId].reputation = 0; // Reputation cannot go below zero
            } else {
                agentCores[_agentId].reputation -= absChange;
            }
        }
        emit AgentReputationUpdated(_agentId, agentCores[_agentId].reputation);
    }

    /**
     * @dev Internal function to apply reputation decay for a given agent.
     * Calculates the decay based on time elapsed since last decay and the `reputationDecayRatePerSecond`.
     * @param _agentId The ID of the agent.
     */
    function _applyReputationDecay(uint256 _agentId) internal {
        uint256 lastDecay = agentCores[_agentId].lastReputationDecay;
        uint256 currentTime = block.timestamp;

        if (currentTime > lastDecay && reputationDecayRatePerSecond > 0) {
            uint256 timeElapsed = currentTime - lastDecay;
            uint256 decayAmount = timeElapsed * reputationDecayRatePerSecond;

            if (agentCores[_agentId].reputation <= decayAmount) {
                agentCores[_agentId].reputation = 0;
            } else {
                agentCores[_agentId].reputation -= decayAmount;
            }
            agentCores[_agentId].lastReputationDecay = currentTime; // Update last decay timestamp
            emit AgentReputationUpdated(_agentId, agentCores[_agentId].reputation);
        }
    }

    /**
     * @dev Triggers a time-based decay of an agent's reputation.
     * Anyone can call this to ensure an agent's reputation is up-to-date, especially before checks.
     * @param _agentId The ID of the agent.
     */
    function decayReputation(uint256 _agentId) public {
        require(_exists(_agentId), "CognitoForgeGuild: Agent does not exist");
        _applyReputationDecay(_agentId); // This simply calls the internal function
    }


    // --- IV. Task Management & Execution ---

    /**
     * @dev Creates a new task for AI agents to participate in.
     * Requires the task creator (a manager) to pay a fee and deposit rewards.
     * @param _taskTitle The title of the task.
     * @param _taskDescription A detailed description of the task's objectives.
     * @param _rewardAmount The reward (in native token) for the agent successfully completing the task.
     * @param _requiredReputation Minimum reputation an agent needs to register for this task.
     * @param _verificationBounty Reward for each verifier involved in the task.
     * @param _verificationDeadline Timestamp when verification must be completed.
     * @param _registrationDuration Time in seconds for agents to register.
     * @return The ID of the newly created task.
     */
    function createTask(
        string memory _taskTitle,
        string memory _taskDescription,
        uint256 _rewardAmount,
        uint256 _requiredReputation,
        uint256 _verificationBounty,
        uint256 _verificationDeadline,
        uint256 _registrationDuration
    ) public payable onlyManager whenNotPaused returns (uint256) {
        // Example: Require funds for fee, agent reward, and at least 3 verifier bounties.
        // The actual number of verifiers assigned can vary.
        require(msg.value >= taskCreationFee + _rewardAmount + _verificationBounty * 3,
            "CognitoForgeGuild: Insufficient funds for task creation (fee + reward + verification bounty)");
        require(_registrationDuration > 0, "CognitoForgeGuild: Registration duration must be positive");
        require(_verificationDeadline > block.timestamp + _registrationDuration, "CognitoForgeGuild: Verification deadline must be after registration");

        _taskIds.increment();
        uint256 newTaskId = _taskIds.current();

        tasks[newTaskId].taskId = newTaskId;
        tasks[newTaskId].title = _taskTitle;
        tasks[newTaskId].description = _taskDescription;
        tasks[newTaskId].rewardAmount = _rewardAmount;
        tasks[newTaskId].requiredReputation = _requiredReputation;
        tasks[newTaskId].verificationBounty = _verificationBounty;
        tasks[newTaskId].verificationDeadline = _verificationDeadline;
        tasks[newTaskId].taskCreator = msg.sender;
        tasks[newTaskId].status = TaskStatus.Open;
        tasks[newTaskId].registrationStart = block.timestamp;
        tasks[newTaskId].registrationEnd = block.timestamp + _registrationDuration;
        // Mappings within Task struct are initialized empty by default.

        emit TaskCreated(newTaskId, msg.sender, _taskTitle, _rewardAmount);
        return newTaskId;
    }

    /**
     * @dev Allows a qualified AI agent to register its intent to perform a specific task.
     * An agent must meet the required reputation and register within the designated period.
     * @param _taskId The ID of the task.
     * @param _agentId The ID of the agent.
     */
    function registerForTask(uint256 _taskId, uint256 _agentId) public whenNotPaused {
        require(_exists(_agentId), "CognitoForgeGuild: Agent does not exist");
        require(ownerOf(_agentId) == msg.sender, "CognitoForgeGuild: Only agent owner can register");
        require(tasks[_taskId].taskId != 0, "CognitoForgeGuild: Task does not exist");
        require(tasks[_taskId].status == TaskStatus.Open || tasks[_taskId].status == TaskStatus.Registered, "CognitoForgeGuild: Task not open for registration");
        require(block.timestamp <= tasks[_taskId].registrationEnd, "CognitoForgeGuild: Registration period has ended");
        
        _applyReputationDecay(_agentId); // Ensure up-to-date reputation check
        require(agentCores[_agentId].reputation >= tasks[_taskId].requiredReputation, "CognitoForgeGuild: Agent does not meet reputation requirement");
        require(!tasks[_taskId].registeredAgents[_agentId], "CognitoForgeGuild: Agent already registered for this task");

        tasks[_taskId].registeredAgents[_agentId] = true;
        tasks[_taskId].status = TaskStatus.Registered; // Update task status if first agent registers
        emit AgentRegisteredForTask(_taskId, _agentId);
    }

    /**
     * @dev An agent submits a cryptographic hash of its task output for future verification.
     * The actual task output is off-chain, and its integrity is guaranteed by the hash.
     * @param _taskId The ID of the task.
     * @param _agentId The ID of the agent.
     * @param _resultHash The hash of the off-chain task result.
     */
    function submitTaskResultHash(uint256 _taskId, uint256 _agentId, bytes32 _resultHash) public whenNotPaused {
        require(_exists(_agentId), "CognitoForgeGuild: Agent does not exist");
        require(ownerOf(_agentId) == msg.sender, "CognitoForgeGuild: Only agent owner can submit results");
        require(tasks[_taskId].taskId != 0, "CognitoForgeGuild: Task does not exist");
        require(tasks[_taskId].registeredAgents[_agentId], "CognitoForgeGuild: Agent not registered for this task");
        require(tasks[_taskId].submittedResults[_agentId] == bytes32(0), "CognitoForgeGuild: Agent already submitted result for this task");
        require(tasks[_taskId].status == TaskStatus.Registered || tasks[_taskId].status == TaskStatus.Submitted, "CognitoForgeGuild: Task not in submission phase");
        require(block.timestamp > tasks[_taskId].registrationEnd, "CognitoForgeGuild: Cannot submit before registration ends"); // Submission period starts after registration

        tasks[_taskId].submittedResults[_agentId] = _resultHash;
        tasks[_taskId].status = TaskStatus.Submitted; // Update task status once results are submitted
        emit TaskResultSubmitted(_taskId, _agentId, _resultHash);
    }

    /**
     * @dev Guild managers assign external verifiers to a task. Verifiers must hold VERIFIER_ROLE.
     * Verifiers are crucial for off-chain verification of AI task results.
     * @param _taskId The ID of the task.
     * @param _verifiers An array of addresses to assign as verifiers.
     */
    function assignVerifiersToTask(uint256 _taskId, address[] memory _verifiers) public onlyManager whenNotPaused {
        require(tasks[_taskId].taskId != 0, "CognitoForgeGuild: Task does not exist");
        require(tasks[_taskId].status == TaskStatus.Submitted, "CognitoForgeGuild: Task not in submission state, cannot assign verifiers yet");
        require(_verifiers.length > 0, "CognitoForgeGuild: At least one verifier must be assigned");

        for (uint256 i = 0; i < _verifiers.length; i++) {
            require(hasRole(VERIFIER_ROLE, _verifiers[i]), "CognitoForgeGuild: Assigned address is not a verifier");
            tasks[_taskId].assignedVerifiers[_verifiers[i]] = true; // Mark verifier as assigned for this task
            // Future: Implement a staking mechanism here, e.g., require(_verifiers[i].stake >= verificationStakeAmount);
        }
        emit VerifiersAssigned(_taskId, _verifiers);
    }

    /**
     * @dev A verifier submits their assessment of an agent's task performance.
     * This report is critical for determining task success and agent rewards/reputation.
     * @param _taskId The ID of the task.
     * @param _agentId The ID of the agent being verified.
     * @param _isSuccessful True if the task was completed successfully by the agent, false otherwise.
     * @param _feedback Optional feedback string from the verifier (can be an IPFS CID for long text).
     */
    function submitVerificationReport(
        uint256 _taskId,
        uint256 _agentId,
        bool _isSuccessful,
        string memory _feedback // Placeholder for detailed feedback (e.g., IPFS CID)
    ) public onlyVerifier whenNotPaused {
        require(tasks[_taskId].taskId != 0, "CognitoForgeGuild: Task does not exist");
        require(tasks[_taskId].assignedVerifiers[msg.sender], "CognitoForgeGuild: Caller is not assigned as verifier for this task");
        require(tasks[_taskId].submittedResults[_agentId] != bytes32(0), "CognitoForgeGuild: Agent has not submitted result for this task");
        require(block.timestamp < tasks[_taskId].verificationDeadline, "CognitoForgeGuild: Verification deadline passed");
        require(!tasks[_taskId].verifierReportsSubmitted[msg.sender][_agentId], "CognitoForgeGuild: Verifier already submitted report for this agent and task");
        
        tasks[_taskId].verifierReportsSubmitted[msg.sender][_agentId] = true;
        tasks[_taskId].verifierReportSuccess[msg.sender][_agentId] = _isSuccessful;

        emit VerificationReportSubmitted(_taskId, _agentId, msg.sender, _isSuccessful);
    }

    /**
     * @dev Guild managers finalize a task, distributing rewards and updating agent reputations
     * based on verifier reports. This function determines the winning agent (if any) and processes payments.
     * A simple majority or threshold can be used to determine success.
     * @param _taskId The ID of the task to resolve.
     */
    function resolveTask(uint256 _taskId) public onlyManager whenNotPaused {
        Task storage task = tasks[_taskId];
        require(task.taskId != 0, "CognitoForgeGuild: Task does not exist");
        require(task.status == TaskStatus.Submitted, "CognitoForgeGuild: Task not in submission state, or already resolved/disputed");
        require(block.timestamp >= task.verificationDeadline, "CognitoForgeGuild: Verification period not over yet");

        uint256 maxSuccesses = 0;
        uint256 bestAgentId = 0;
        
        // Iterate through all agents that registered and submitted results
        uint256[] memory registeredAgentIds = _getRegisteredAgentIdsForTask(_taskId);
        for (uint252 i = 0; i < registeredAgentIds.length; i++) {
            uint256 currentAgentId = registeredAgentIds[i];
            if (task.submittedResults[currentAgentId] == bytes32(0)) continue; // Skip agents who didn't submit

            uint256 agentSuccesses = 0;
            // Count successful reports for this specific agent from all assigned verifiers
            for (address verifier : _getAssignedVerifiersForTask(_taskId)) {
                if (task.verifierReportsSubmitted[verifier][currentAgentId] && task.verifierReportSuccess[verifier][currentAgentId]) {
                    agentSuccesses++;
                }
            }

            // Determine the agent with the most successful verifications
            if (agentSuccesses > maxSuccesses) {
                maxSuccesses = agentSuccesses;
                bestAgentId = currentAgentId;
            }
        }

        if (bestAgentId != 0 && maxSuccesses > 0) {
            task.winningAgentId = bestAgentId;
            task.status = TaskStatus.Resolved;

            // Distribute rewards to winning agent
            address payable agentOwner = payable(ownerOf(bestAgentId));
            (bool successAgent, ) = agentOwner.call{value: task.rewardAmount}("");
            require(successAgent, "CognitoForgeGuild: Failed to pay agent reward");
            
            // Update agent's reputation for successful completion
            updateAgentReputation(bestAgentId, 50); // Example: +50 reputation for success
            agentCores[bestAgentId].tasksCompleted++;

            // Distribute bounties to verifiers who reported success for the winning agent
            for (address verifier : _getAssignedVerifiersForTask(_taskId)) {
                if (task.verifierReportsSubmitted[verifier][bestAgentId] && task.verifierReportSuccess[verifier][bestAgentId]) {
                    (bool successVerifier, ) = payable(verifier).call{value: task.verificationBounty}("");
                    require(successVerifier, "CognitoForgeGuild: Failed to pay verifier bounty");
                }
            }
            emit TaskResolved(_taskId, bestAgentId, task.rewardAmount, 50);

        } else {
            // No agent successfully completed the task or no sufficient verification.
            task.status = TaskStatus.Resolved; // Task is resolved even if no winner
            emit TaskResolved(_taskId, 0, 0, 0); // Emit with 0 winning agent
        }
    }

    /**
     * @dev Internal helper to get a list of agent IDs registered for a specific task.
     * Note: This function can be inefficient if the number of agents is very large,
     * as it iterates through all possible agent IDs. For production, consider storing
     * registered agent IDs in a dynamic array within the Task struct.
     * @param _taskId The ID of the task.
     * @return An array of agent IDs.
     */
    function _getRegisteredAgentIdsForTask(uint256 _taskId) internal view returns (uint256[] memory) {
        uint256 count = 0;
        // Iterate only up to the current total number of minted agents.
        // Still potentially inefficient if many agents exist but few are registered.
        for (uint224 i = 1; i <= _agentIds.current(); i++) {
            if (tasks[_taskId].registeredAgents[i]) {
                count++;
            }
        }
        uint256[] memory agentList = new uint256[](count);
        uint256 currentIdx = 0;
        for (uint252 i = 1; i <= _agentIds.current(); i++) {
            if (tasks[_taskId].registeredAgents[i]) {
                agentList[currentIdx] = i;
                currentIdx++;
            }
        }
        return agentList;
    }

    /**
     * @dev Internal helper to get a list of assigned verifier addresses for a specific task.
     * Similar to _getRegisteredAgentIdsForTask, this can be inefficient and might benefit
     * from storing assigned verifiers in a dynamic array directly in the Task struct.
     * @param _taskId The ID of the task.
     * @return An array of verifier addresses.
     */
    function _getAssignedVerifiersForTask(uint256 _taskId) internal view returns (address[] memory) {
        // AccessControl provides getRoleMemberCount and getRoleMember, but iterating over all
        // verifiers and checking `tasks[_taskId].assignedVerifiers[verifier]` is still inefficient.
        // A better design for large-scale would be to store assigned verifiers as a dynamic array in the Task struct.
        uint256 count = 0;
        for (uint252 i = 0; i < getRoleMemberCount(VERIFIER_ROLE); i++) {
            address verifierAddress = getRoleMember(VERIFIER_ROLE, i);
            if (tasks[_taskId].assignedVerifiers[verifierAddress]) {
                count++;
            }
        }
        address[] memory assignedList = new address[](count);
        uint256 currentIdx = 0;
        for (uint252 i = 0; i < getRoleMemberCount(VERIFIER_ROLE); i++) {
            address verifierAddress = getRoleMember(VERIFIER_ROLE, i);
            if (tasks[_taskId].assignedVerifiers[verifierAddress]) {
                assignedList[currentIdx] = verifierAddress;
                currentIdx++;
            }
        }
        return assignedList;
    }


    /**
     * @dev Retrieves comprehensive details about a specific task.
     * @param _taskId The ID of the task.
     * @return All relevant fields of the Task struct.
     */
    function getTaskDetails(uint256 _taskId) public view returns (
        uint256 taskId,
        string memory title,
        string memory description,
        uint256 rewardAmount,
        uint256 requiredReputation,
        uint256 verificationBounty,
        uint256 verificationDeadline,
        address taskCreator,
        TaskStatus status,
        uint256 registrationStart,
        uint256 registrationEnd,
        uint256 winningAgentId
    ) {
        require(tasks[_taskId].taskId != 0, "CognitoForgeGuild: Task does not exist");
        Task storage task = tasks[_taskId];
        return (
            task.taskId,
            task.title,
            task.description,
            task.rewardAmount,
            task.requiredReputation,
            task.verificationBounty,
            task.verificationDeadline,
            task.taskCreator,
            task.status,
            task.registrationStart,
            task.registrationEnd,
            task.winningAgentId
        );
    }


    // --- V. Knowledge Base Contribution & Access ---

    /**
     * @dev An agent contributes a piece of verifiable knowledge (referenced by IPFS CID and content hash)
     * to the guild's shared base. This can optionally provide a reputation boost for the contributing agent.
     * @param _agentId The ID of the contributing agent.
     * @param _title The title of the knowledge fragment.
     * @param _ipfsCid The IPFS Content Identifier (CID) pointing to the knowledge content.
     * @param _contentHash A cryptographic hash of the knowledge content for integrity verification.
     * @return The ID of the newly contributed knowledge fragment.
     */
    function contributeKnowledgeFragment(
        uint256 _agentId,
        string memory _title,
        string memory _ipfsCid,
        bytes32 _contentHash
    ) public whenNotPaused returns (uint256) {
        require(_exists(_agentId), "CognitoForgeGuild: Agent does not exist");
        require(ownerOf(_agentId) == msg.sender, "CognitoForgeGuild: Only agent owner can contribute knowledge");
        require(bytes(_ipfsCid).length > 0, "CognitoForgeGuild: IPFS CID cannot be empty");
        require(_contentHash != bytes32(0), "CognitoForgeGuild: Content hash cannot be empty");

        _fragmentIds.increment();
        uint256 newFragmentId = _fragmentIds.current();

        knowledgeBase[newFragmentId] = KnowledgeFragment({
            fragmentId: newFragmentId,
            agentId: _agentId,
            title: _title,
            ipfsCid: _ipfsCid,
            contentHash: _contentHash,
            contributedAt: block.timestamp,
            accessCost: 0, // Default to free access, can be configured later
            requiredReputation: 0 // Default, can be configured later
        });

        updateAgentReputation(_agentId, 10); // Example: +10 reputation for contributing knowledge
        agentCores[_agentId].knowledgeFragmentsContributed++;

        emit KnowledgeFragmentContributed(newFragmentId, _agentId, _title, _ipfsCid);
        return newFragmentId;
    }

    /**
     * @dev Allows a qualified agent to request (and potentially pay for) access to a knowledge fragment.
     * This function records the request on-chain; actual data transfer is handled off-chain.
     * @param _agentId The ID of the requesting agent.
     * @param _fragmentId The ID of the knowledge fragment.
     */
    function requestKnowledgeFragment(uint256 _agentId, uint256 _fragmentId) public payable whenNotPaused {
        require(_exists(_agentId), "CognitoForgeGuild: Agent does not exist");
        require(ownerOf(_agentId) == msg.sender, "CognitoForgeGuild: Only agent owner can request knowledge");
        require(knowledgeBase[_fragmentId].fragmentId != 0, "CognitoForgeGuild: Knowledge fragment does not exist");
        
        _applyReputationDecay(_agentId); // Ensure up-to-date reputation for access check
        require(agentCores[_agentId].reputation >= knowledgeBase[_fragmentId].requiredReputation, "CognitoForgeGuild: Agent does not meet reputation requirement for access");
        require(msg.value >= knowledgeBase[_fragmentId].accessCost, "CognitoForgeGuild: Insufficient payment for knowledge fragment access");

        // If there's an access cost, funds are transferred (e.g., to treasury or contributing agent)
        if (knowledgeBase[_fragmentId].accessCost > 0) {
            // For simplicity, for now, paid access cost goes to the contract treasury.
            // In a more complex system, it could go to the contributing agent or a split.
        }

        emit KnowledgeFragmentRequested(_fragmentId, _agentId);
        // Off-chain systems should monitor this event to grant access to the IPFS CID.
    }

    /**
     * @dev Retrieves metadata (excluding actual content) about a knowledge fragment.
     * This allows agents to discover fragments before requesting full access.
     * @param _fragmentId The ID of the knowledge fragment.
     * @return All metadata fields of the KnowledgeFragment struct.
     */
    function getKnowledgeFragmentDetails(uint256 _fragmentId) public view returns (
        uint256 fragmentId,
        uint256 agentId,
        string memory title,
        string memory ipfsCid,
        bytes32 contentHash,
        uint256 contributedAt,
        uint256 accessCost,
        uint256 requiredReputation
    ) {
        require(knowledgeBase[_fragmentId].fragmentId != 0, "CognitoForgeGuild: Knowledge fragment does not exist");
        KnowledgeFragment storage fragment = knowledgeBase[_fragmentId];
        return (
            fragment.fragmentId,
            fragment.agentId,
            fragment.title,
            fragment.ipfsCid,
            fragment.contentHash,
            fragment.contributedAt,
            fragment.accessCost,
            fragment.requiredReputation
        );
    }


    // --- VI. Dispute Resolution ---

    /**
     * @dev Allows an agent owner or verifier to raise a dispute regarding task outcomes or reputation changes.
     * This initiates a formal review process for controversial events.
     * @param _taskId The ID of the task involved in the dispute.
     * @param _agentId The ID of the agent involved in the dispute.
     * @param _disputeType The category of the dispute (e.g., TaskOutcome, ReputationAdjustment).
     * @param _reason A brief description outlining the reason for the dispute.
     * @return The ID of the newly created dispute.
     */
    function raiseDispute(
        uint256 _taskId,
        uint256 _agentId,
        DisputeType _disputeType,
        string memory _reason
    ) public whenNotPaused returns (uint256) {
        require(tasks[_taskId].taskId != 0, "CognitoForgeGuild: Task does not exist");
        require(_exists(_agentId), "CognitoForgeGuild: Agent does not exist");
        require(ownerOf(_agentId) == msg.sender || hasRole(VERIFIER_ROLE, msg.sender), "CognitoForgeGuild: Only agent owner or verifier can raise dispute");
        require(tasks[_taskId].status == TaskStatus.Resolved, "CognitoForgeGuild: Task not in a resolvable state for dispute"); // Only dispute resolved tasks

        _disputeIds.increment();
        uint256 newDisputeId = _disputeIds.current();

        disputes[newDisputeId] = Dispute({
            disputeId: newDisputeId,
            taskId: _taskId,
            agentId: _agentId,
            reporter: msg.sender,
            disputeType: _disputeType,
            reason: _reason,
            raisedAt: block.timestamp,
            resolved: false,
            isAgentInFavor: false, // Default initial value
            reputationAdjustment: 0, // Default initial value
            rewardReallocation: 0 // Default initial value
        });
        // Mappings within the struct (evidenceCIDs) are implicitly empty.

        tasks[_taskId].status = TaskStatus.Disputed; // Set task to disputed status, preventing further actions until resolved

        emit DisputeRaised(newDisputeId, _taskId, _agentId, _disputeType, msg.sender);
        return newDisputeId;
    }

    /**
     * @dev Parties involved in a dispute can submit IPFS CIDs pointing to their evidence.
     * This evidence is then reviewed by managers or arbitrators.
     * @param _disputeId The ID of the dispute.
     * @param _evidenceCID The IPFS CID of the evidence document/file.
     */
    function submitArbitrationEvidence(uint256 _disputeId, string memory _evidenceCID) public whenNotPaused {
        require(disputes[_disputeId].disputeId != 0, "CognitoForgeGuild: Dispute does not exist");
        require(!disputes[_disputeId].resolved, "CognitoForgeGuild: Dispute already resolved");
        require(bytes(_evidenceCID).length > 0, "CognitoForgeGuild: Evidence CID cannot be empty");

        // Only the reporter, agent owner, or involved verifiers can submit evidence
        bool isAllowed = (msg.sender == disputes[_disputeId].reporter || ownerOf(disputes[_disputeId].agentId) == msg.sender);
        // Additional check for verifiers involved in the task
        if (!isAllowed) {
            for (address verifier : _getAssignedVerifiersForTask(disputes[_disputeId].taskId)) {
                if (verifier == msg.sender) {
                    isAllowed = true;
                    break;
                }
            }
        }
        require(isAllowed, "CognitoForgeGuild: Only involved parties can submit evidence");

        disputes[_disputeId].evidenceCIDs[msg.sender] = _evidenceCID;
        emit EvidenceSubmitted(_disputeId, msg.sender, _evidenceCID);
    }

    /**
     * @dev Guild managers (or an arbitration DAO) make a final ruling on a dispute,
     * impacting reputation and potentially reallocating rewards.
     * @param _disputeId The ID of the dispute to resolve.
     * @param _isAgentInFavor True if the dispute resolution favors the agent, false otherwise.
     * @param _reputationAdjustment The reputation change (positive or negative) for the agent due to resolution.
     * @param _rewardReallocation The amount of reward to reallocate (e.g., from/to agent).
     */
    function resolveDispute(
        uint256 _disputeId,
        bool _isAgentInFavor,
        int256 _reputationAdjustment,
        uint256 _rewardReallocation
    ) public onlyManager whenNotPaused {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.disputeId != 0, "CognitoForgeGuild: Dispute does not exist");
        require(!dispute.resolved, "CognitoForgeGuild: Dispute already resolved");

        dispute.resolved = true;
        dispute.isAgentInFavor = _isAgentInFavor;
        dispute.reputationAdjustment = _reputationAdjustment;
        dispute.rewardReallocation = _rewardReallocation;

        // Apply the reputation adjustment for the agent
        updateAgentReputation(dispute.agentId, _reputationAdjustment);

        // Handle reward reallocation based on dispute outcome
        if (_rewardReallocation > 0) {
            if (_isAgentInFavor) { // Agent wins dispute, receives reallocated funds
                address payable agentOwner = payable(ownerOf(dispute.agentId));
                (bool success, ) = agentOwner.call{value: _rewardReallocation}("");
                require(success, "CognitoForgeGuild: Failed to reallocate reward to agent");
            } else { // Agent loses dispute, funds might be reallocated from them or stay in treasury
                // For this example, if agent loses, the reallocation means the funds are not given to them,
                // or are instead used to compensate other parties (not explicitly coded here without more complex escrow).
            }
        }

        // Return task status to resolved or a new 'finalized' state
        tasks[dispute.taskId].status = TaskStatus.Resolved; 

        emit DisputeResolved(_disputeId, _isAgentInFavor, _reputationAdjustment, _rewardReallocation);
    }


    // --- VII. Governance & Parameters ---

    /**
     * @dev Managers can adjust the rate at which agent reputation decays over time.
     * This parameter allows the guild to fine-tune the importance of recent activity.
     * @param _ratePerSecond The new decay rate in reputation units per second.
     */
    function setReputationDecayRate(uint256 _ratePerSecond) public onlyManager {
        reputationDecayRatePerSecond = _ratePerSecond;
    }

    /**
     * @dev Managers can set the fee required to create a new task.
     * This fee helps fund the guild's operations or treasury.
     * @param _fee The new task creation fee in native tokens (e.g., Wei).
     */
    function setTaskCreationFee(uint256 _fee) public onlyManager {
        taskCreationFee = _fee;
    }

    /**
     * @dev Managers can set the amount of tokens verifiers must stake to participate.
     * (Currently, the staking/slashing mechanism is conceptual and not fully implemented for simplicity).
     * @param _amount The new verification stake amount in native tokens.
     */
    function setVerificationStakeAmount(uint256 _amount) public onlyManager {
        verificationStakeAmount = _amount;
    }

    // --- AccessControl Helpers ---

    /**
     * @dev Returns an array of addresses that have a specific role.
     * Note: This function iterates over all role members and can be gas-expensive
     * if many members exist. It is not suitable for on-chain logic that needs to
     * be frequently called, but useful for off-chain querying or infrequent admin tasks.
     * @param role The role to query (e.g., MANAGER_ROLE, VERIFIER_ROLE).
     * @return An array of addresses holding the specified role.
     */
    function getRoleMembers(bytes32 role) public view returns (address[] memory) {
        uint256 count = getRoleMemberCount(role);
        address[] memory members = new address[](count);
        for (uint256 i = 0; i < count; i++) {
            members[i] = getRoleMember(role, i);
        }
        return members;
    }

    // --- ERC721 Overrides for AccessControl and Pausable ---
    // These ensure that standard OpenZeppelin functions are compatible with
    // AccessControl and Pausable functionalities.
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    // Required for compatibility with ERC721Upgradeable in some contexts, or newer OpenZeppelin versions.
    // In this non-upgradeable context, `ERC721` is sufficient.
    function _update(address to, uint256 tokenId, address auth) internal override(ERC721, IERC721) returns (address) {
        return super._update(to, tokenId, auth);
    }
}

```