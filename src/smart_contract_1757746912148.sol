This smart contract, named `SynergosAI`, implements a decentralized marketplace for AI-driven tasks. It aims to connect "Requesters" who need AI services with "Agents" who provide computational resources and AI models.

The contract incorporates several advanced concepts:
*   **Reputation System:** Agents earn reputation for successful task completion and lose it for failures, influencing their eligibility for future tasks.
*   **Verifiable Computation Abstraction:** While the contract doesn't perform AI or ZKP verification on-chain, it provides an interface to manage "proof identifiers" (e.g., hashes of ZKPs or attestations) submitted by agents, which can be verified off-chain.
*   **Dynamic Task Lifecycle:** Tasks go through multiple states, including bidding, agent selection, completion claims, challenges, and dispute resolution.
*   **Flexible Payment & Escrow:** Task rewards are held in escrow, released upon confirmation, and adjusted for platform fees and agent bids.
*   **Agent Staking:** Agents stake collateral, providing a financial incentive for honest behavior and a source for penalties.
*   **Capability Matching:** Requesters can specify required capabilities, and the contract ensures only agents with those capabilities can bid.
*   **Dispute Resolution Mechanism:** Designed to be resolved by the contract owner (or an off-chain DAO/oracle), demonstrating an important integration pattern for complex off-chain outcomes.

It avoids common open-source patterns by focusing specifically on a *network of AI agents* rather than just general computation, and by integrating a bespoke reputation system linked directly to task performance and dispute outcomes.

---

## Smart Contract Outline and Function Summary

**Contract Name:** `SynergosAI`

**Core Concept:** A decentralized marketplace connecting "Requesters" with "AI Agents" for task execution, featuring payment escrow, reputation management, and dispute resolution.

**I. Core Infrastructure & Management (Owner/Admin Functions)**
1.  **`constructor(address _feeRecipient, uint256 _platformFeeRate)`**: Initializes the contract owner, platform fee recipient, and the percentage rate for fees.
2.  **`updateFeeRecipient(address _newRecipient)`**: Allows the owner to change the address designated to receive platform fees.
3.  **`updatePlatformFeeRate(uint256 _newRate)`**: Allows the owner to adjust the platform fee percentage (e.g., 500 for 5%).
4.  **`pauseContract()`**: Pauses all core operational functions of the contract, preventing most state-changing transactions (emergency stop).
5.  **`unpauseContract()`**: Unpauses the contract, restoring normal operations after an emergency.
6.  **`withdrawPlatformFees()`**: Allows the designated fee recipient to withdraw accumulated platform fees from the contract.

**II. Provider Management (AI Agents Offering Services)**
7.  **`registerAgent(bytes32[] calldata _capabilities)`**: Allows an address to register as an AI Agent by staking a minimum collateral (ETH) and declaring their AI capabilities (e.g., hashes of "NLP", "Image Recognition").
8.  **`updateAgentCapabilities(bytes32[] calldata _newCapabilities)`**: Allows a registered agent to update their listed specializations and skills.
9.  **`deregisterAgent()`**: Allows an agent to initiate the deregistration process, which locks their staked collateral until all active tasks are settled and a cooldown period passes.
10. **`reclaimAgentStake()`**: Allows a deregistered agent to retrieve their staked collateral after completing all outstanding tasks and waiting for the defined cooldown period.
11. **`slashAgentStake(address _agent, uint256 _amount)`**: Allows the owner (or an authorized dispute resolver) to penalize an agent by reducing their staked collateral, typically due to misconduct or failed tasks.

**III. Task Management (Requesters Posting & Managing Tasks)**
12. **`createTask(string memory _taskDescription, bytes32 _dataCID, bytes32[] calldata _requiredCapabilities, uint256 _reward, uint256 _challengeWindow, uint256 _minAgentReputation)`**: A requester posts a new AI task, specifying requirements, input data (via CID), desired reward, a challenge period, and minimum agent reputation. The reward amount is deposited into escrow.
13. **`bidForTask(uint256 _taskId, uint256 _bidAmount)`**: Registered agents can submit a bid for an open task. The bid amount can be less than or equal to the requester's specified reward. Agent capabilities and reputation are checked.
14. **`selectAgentForTask(uint256 _taskId, address _agentAddress)`**: The requester reviews bids and selects an agent to perform the task. This moves the task from `OpenForBids` to `Assigned`.
15. **`submitTaskCompletionClaim(uint256 _taskId, bytes32 _proofIdentifier, bytes32 _outputCID)`**: The selected agent claims task completion, providing an identifier for off-chain verifiable proof (e.g., ZKP hash) and the output data CID.
16. **`challengeTaskCompletion(uint256 _taskId)`**: The requester can dispute a claimed task completion within a set time window, moving the task to a `Challenged` state.
17. **`resolveDispute(uint256 _taskId, bool _agentWins)`**: The owner (acting as a dispute resolver) determines the outcome of a challenged task. This decision affects fund distribution and agent reputation.
18. **`confirmTaskCompletion(uint256 _taskId)`**: The requester explicitly confirms the satisfactory completion of a task after the challenge window closes (or if no challenge was raised), releasing the reward (minus fees) to the agent and updating their reputation.
19. **`cancelTask(uint256 _taskId)`**: The requester can cancel a task only if it is still in the `OpenForBids` state, retrieving their deposited reward.
20. **`withdrawTaskFundsByRequester(uint256 _taskId)`**: Allows the requester to withdraw funds that are due to them (e.g., after task cancellation, dispute resolution in their favor, or the difference if the agent's bid was less than the initial reward).
21. **`withdrawTaskFundsByAgent(uint256 _taskId)`**: Allows the selected agent to withdraw their payment for tasks that have been successfully confirmed or resolved in their favor.

**IV. Reputation & Dynamic Features**
22. **`getAgentReputation(address _agent)`**: A view function to query the current reputation score of a specific AI agent.
23. **`increaseAgentReputation(address _agent, uint256 _points)`**: Owner/DAO can manually increase an agent's reputation score, useful for rewarding exceptional off-chain contributions.
24. **`decreaseAgentReputation(address _agent, uint256 _points)`**: Owner/DAO can manually decrease an agent's reputation score, useful for penalizing verified off-chain misconduct not directly tied to a task dispute.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Custom Errors
error Unauthorized();
error AgentNotRegistered();
error AgentAlreadyRegistered();
error InsufficientStake();
error TaskNotFound();
error TaskNotInOpenState();
error TaskNotAssigned();
error TaskAlreadyAssigned();
error TaskNotCompleted(); // Redundant for clarity with specific status checks
error TaskAlreadyCompleted(); // Redundant for clarity with specific status checks
error TaskCannotBeCancelled();
error InvalidTaskStatus();
error InvalidBidAmount();
error RequesterNotTaskCreator();
error AgentNotSelectedForTask();
error AgentAlreadyBid();
error NoBidsSubmitted(); // Redundant, checked by _taskBids[agentAddress] == 0
error DisputeAlreadyResolved(); // Redundant, checked by status
error DisputeNotPending();
error TaskNotDueForStakeReclaim();
error InvalidPlatformFeeRate();
error ZeroAddressNotAllowed();
error NothingToWithdraw();
error MinimumReputationNotMet();
error AgentDoesNotPossessAllRequiredCapabilities();

/**
 * @title SynergosAI - Decentralized AI Agent Network for Research & Data Analysis
 * @dev This contract facilitates a marketplace for AI-driven tasks, connecting Requesters with AI Agents.
 *      It manages task creation, agent bidding, payment escrow, reputation tracking, and dispute resolution.
 *      It's designed to be advanced by abstracting off-chain verifiable computation (e.g., ZKPs)
 *      through proof identifiers and integrating a reputation system to incentivize honest and performant agents.
 *      It does NOT perform AI computation or store sensitive data on-chain.
 *      Data access and verifiable proofs are assumed to be handled off-chain, with hashes/IDs managed here.
 *      The contract uses a basic reputation system, agent staking, and a multi-stage task lifecycle.
 */
contract SynergosAI is Ownable, Pausable, ReentrancyGuard {
    using SafeMath for uint256;

    // --- Outline and Function Summary ---

    // I. Core Infrastructure & Management (Owner/Admin Functions)
    // 1. constructor(address _feeRecipient, uint256 _platformFeeRate): Initializes the contract owner, platform fee recipient, and fee rate.
    // 2. updateFeeRecipient(address _newRecipient): Allows owner to change the address receiving platform fees.
    // 3. updatePlatformFeeRate(uint256 _newRate): Allows owner to adjust the percentage of task rewards taken as a platform fee.
    // 4. pauseContract(): Pauses all core operations of the contract in case of emergency.
    // 5. unpauseContract(): Unpauses the contract, restoring normal operations.
    // 6. withdrawPlatformFees(): Allows the platform fee recipient to withdraw accumulated fees.

    // II. Provider Management (AI Agents Offering Services)
    // 7. registerAgent(bytes32[] calldata _capabilities): Allows an address to register as an AI Agent by staking collateral and defining their skills.
    // 8. updateAgentCapabilities(bytes32[] calldata _newCapabilities): Allows a registered agent to update their list of capabilities.
    // 9. deregisterAgent(): Allows an agent to initiate deregistration, locking their stake until tasks are settled.
    // 10. reclaimAgentStake(): Allows a deregistered agent to reclaim their stake after all associated tasks are settled and a cooldown period passes.
    // 11. slashAgentStake(address _agent, uint256 _amount): Owner/Dispute resolver can penalize an agent by slashing a portion of their stake.

    // III. Task Management (Requesters Posting & Managing Tasks)
    // 12. createTask(string memory _taskDescription, bytes32 _dataCID, bytes32[] calldata _requiredCapabilities, uint256 _reward, uint256 _challengeWindow, uint256 _minAgentReputation): Requester posts a new AI task, defining requirements and depositing the reward.
    // 13. bidForTask(uint256 _taskId, uint256 _bidAmount): Registered agents can bid on an open task. Bid amount can be less than or equal to reward.
    // 14. selectAgentForTask(uint256 _taskId, address _agentAddress): Requester selects a bidding agent to perform the task.
    // 15. submitTaskCompletionClaim(uint256 _taskId, bytes32 _proofIdentifier, bytes32 _outputCID): Selected agent claims task completion, providing a verifiable proof ID and output CID.
    // 16. challengeTaskCompletion(uint256 _taskId): Requester can dispute a completion claim within the challenge window.
    // 17. resolveDispute(uint256 _taskId, bool _agentWins): Owner/Dispute resolver determines the outcome of a disputed task.
    // 18. confirmTaskCompletion(uint256 _taskId): Requester confirms satisfactory completion of a task, releasing funds to the agent.
    // 19. cancelTask(uint256 _taskId): Requester can cancel an unassigned task and retrieve their deposited funds.
    // 20. withdrawTaskFundsByRequester(uint256 _taskId): Allows requester to withdraw funds after a task is cancelled, failed, or if an agent bid less than the initial reward.
    // 21. withdrawTaskFundsByAgent(uint256 _taskId): Allows agent to withdraw payment for confirmed tasks or after a dispute resolves in their favor.

    // IV. Reputation & Dynamic Features
    // 22. getAgentReputation(address _agent): Queries the current reputation score of a specific agent.
    // 23. increaseAgentReputation(address _agent, uint256 _points): Owner/DAO can manually increase an agent's reputation.
    // 24. decreaseAgentReputation(address _agent, uint256 _points): Owner/DAO can manually decrease an agent's reputation.

    // --- State Variables ---

    uint256 public constant MIN_AGENT_STAKE = 1 ether; // Minimum stake required to register as an agent
    uint256 public constant AGENT_STAKE_COOLDOWN_PERIOD = 7 days; // Time to wait after deregistration before reclaiming stake

    uint256 private _nextTaskId;
    uint256 private _platformFeesAccumulated; // Total fees collected by the platform

    address public feeRecipient; // Address to receive platform fees
    uint256 public platformFeeRate; // Percentage of task reward taken as fee (e.g., 500 for 5%) - 10000 basis points = 100%

    // --- Enums ---

    enum TaskStatus {
        OpenForBids,
        Assigned,
        AgentClaimedCompletion,
        Challenged,
        Completed,
        Cancelled,
        Failed
    }

    // --- Structs ---

    struct Agent {
        bool isRegistered;
        uint256 stake;
        bytes32[] capabilities; // List of service capabilities (e.g., hashes of "NLP", "Image Recognition")
        uint256 deregisterTimestamp; // Timestamp when deregistration was initiated
        uint256 activeTasksCount; // Number of tasks currently assigned or awaiting settlement
    }

    struct Task {
        address requester;
        address selectedAgent; // The agent chosen to perform the task
        uint256 rewardAmount; // The initial reward amount deposited by the requester
        string taskDescription; // IPFS CID or URL for detailed task description
        bytes32 dataCID; // IPFS CID for the input data (assumed to be encrypted/private if necessary)
        bytes32[] requiredCapabilities; // Capabilities an agent must have
        bytes32 outputCID; // IPFS CID for the result data (submitted by agent)
        bytes32 proofIdentifier; // Hash or ID for off-chain verifiable proof (e.g., ZKP hash)
        uint256 minAgentReputation; // Minimum reputation an agent must have to be selected
        uint256 submissionTimestamp; // Timestamp when agent submitted completion claim
        uint256 challengeWindowEnd; // Timestamp when the challenge period ends
        TaskStatus status;
        uint256 creationTimestamp; // When the task was created
        uint256 selectedBidAmount; // The amount the selected agent bid for the task (can be <= rewardAmount)
        uint256 platformFeeCollected; // Fee collected for this task
    }

    // Agent's address => Agent details
    mapping(address => Agent) public agents;
    // Task ID => Task details
    mapping(uint256 => Task) public tasks;
    // Task ID => Agent addresses that have bid
    mapping(uint256 => address[]) private _taskBidders;
    // Task ID => Agent address => Bid amount
    mapping(uint256 => mapping(address => uint256)) private _taskBids;
    // Agent address => Reputation score
    mapping(address => uint256) public agentReputation;
    // Agent address => List of task IDs they are involved in (active or pending settlement)
    mapping(address => uint256[]) public agentActiveTasks;

    // --- Events ---

    event AgentRegistered(address indexed agent, uint256 stake, bytes32[] capabilities);
    event AgentCapabilitiesUpdated(address indexed agent, bytes32[] newCapabilities);
    event AgentDeregistered(address indexed agent, uint256 deregisterTimestamp);
    event AgentStakeReclaimed(address indexed agent, uint256 amount);
    event AgentStakeSlashed(address indexed agent, uint256 amount, address indexed by);
    event TaskCreated(uint256 indexed taskId, address indexed requester, uint256 reward, bytes32[] requiredCapabilities);
    event TaskBid(uint256 indexed taskId, address indexed agent, uint256 bidAmount);
    event AgentSelected(uint256 indexed taskId, address indexed requester, address indexed agent, uint256 selectedBidAmount);
    event TaskCompletionClaimed(uint256 indexed taskId, address indexed agent, bytes32 proofIdentifier, bytes32 outputCID);
    event TaskCompletionChallenged(uint256 indexed taskId, address indexed requester);
    event DisputeResolved(uint256 indexed taskId, bool agentWins, address indexed resolver);
    event TaskConfirmed(uint256 indexed taskId, address indexed requester, address indexed agent);
    event TaskCancelled(uint256 indexed taskId, address indexed requester);
    event FundsWithdrawn(address indexed recipient, uint256 amount, string purpose);
    event PlatformFeeRecipientUpdated(address indexed oldRecipient, address indexed newRecipient);
    event PlatformFeeRateUpdated(uint256 oldRate, uint256 newRate);
    event PlatformFeesWithdrawn(address indexed recipient, uint256 amount);
    event AgentReputationIncreased(address indexed agent, uint256 points);
    event AgentReputationDecreased(address indexed agent, uint256 points);

    // --- Modifiers ---

    modifier onlyAgent(address _agent) {
        if (!agents[_agent].isRegistered) {
            revert AgentNotRegistered();
        }
        _;
    }

    modifier onlyRequester(uint256 _taskId) {
        if (tasks[_taskId].requester != msg.sender) {
            revert RequesterNotTaskCreator();
        }
        _;
    }

    /**
     * @dev Initializes the contract with an initial owner, fee recipient, and platform fee rate.
     * @param _feeRecipient The address that will receive platform fees.
     * @param _platformFeeRate The percentage rate for platform fees (e.g., 500 for 5%). Max 10000.
     */
    constructor(address _feeRecipient, uint256 _platformFeeRate) Ownable(msg.sender) {
        if (_feeRecipient == address(0)) revert ZeroAddressNotAllowed();
        if (_platformFeeRate > 10000) revert InvalidPlatformFeeRate(); // Max 100% (10000 basis points)
        feeRecipient = _feeRecipient;
        platformFeeRate = _platformFeeRate;
        _nextTaskId = 1;
    }

    // --- I. Core Infrastructure & Management (Owner/Admin) ---

    /**
     * @dev Allows the owner to update the address receiving platform fees.
     * @param _newRecipient The new address for fee collection.
     */
    function updateFeeRecipient(address _newRecipient) external onlyOwner {
        if (_newRecipient == address(0)) revert ZeroAddressNotAllowed();
        emit PlatformFeeRecipientUpdated(feeRecipient, _newRecipient);
        feeRecipient = _newRecipient;
    }

    /**
     * @dev Allows the owner to adjust the platform fee rate.
     * @param _newRate The new fee rate in basis points (e.g., 500 for 5%). Max 10000.
     */
    function updatePlatformFeeRate(uint256 _newRate) external onlyOwner {
        if (_newRate > 10000) revert InvalidPlatformFeeRate();
        emit PlatformFeeRateUpdated(platformFeeRate, _newRate);
        platformFeeRate = _newRate;
    }

    /**
     * @dev Pauses the contract, preventing most state-changing operations.
     *      Inherited from OpenZeppelin's Pausable.
     */
    function pauseContract() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract, allowing normal operations.
     *      Inherited from OpenZeppelin's Pausable.
     */
    function unpauseContract() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Allows the fee recipient to withdraw accumulated platform fees.
     */
    function withdrawPlatformFees() external nonReentrant {
        if (msg.sender != feeRecipient) revert Unauthorized();
        if (_platformFeesAccumulated == 0) revert NothingToWithdraw();

        uint256 amount = _platformFeesAccumulated;
        _platformFeesAccumulated = 0;

        (bool success, ) = feeRecipient.call{value: amount}("");
        if (!success) {
            _platformFeesAccumulated = amount; // Refund if transfer fails
            revert("Failed to withdraw platform fees.");
        }
        emit PlatformFeesWithdrawn(feeRecipient, amount);
    }

    // --- II. Provider Management (AI Agents) ---

    /**
     * @dev Allows an address to register as an AI Agent. Requires staking `MIN_AGENT_STAKE` and defining capabilities.
     * @param _capabilities An array of hashes representing the agent's specializations (e.g., keccak256("NLP")).
     */
    function registerAgent(bytes32[] calldata _capabilities) external payable nonReentrant whenNotPaused {
        if (agents[msg.sender].isRegistered) revert AgentAlreadyRegistered();
        if (msg.value < MIN_AGENT_STAKE) revert InsufficientStake();

        agents[msg.sender] = Agent({
            isRegistered: true,
            stake: msg.value,
            capabilities: _capabilities,
            deregisterTimestamp: 0,
            activeTasksCount: 0
        });
        agentReputation[msg.sender] = 100; // Initialize with a base reputation
        emit AgentRegistered(msg.sender, msg.value, _capabilities);
    }

    /**
     * @dev Allows a registered agent to update their list of capabilities.
     * @param _newCapabilities The new array of hashes representing the agent's updated specializations.
     */
    function updateAgentCapabilities(bytes32[] calldata _newCapabilities) external onlyAgent(msg.sender) whenNotPaused {
        agents[msg.sender].capabilities = _newCapabilities;
        emit AgentCapabilitiesUpdated(msg.sender, _newCapabilities);
    }

    /**
     * @dev Allows an agent to initiate deregistration. Their stake is locked until all active tasks are settled
     *      and a cooldown period passes.
     */
    function deregisterAgent() external onlyAgent(msg.sender) whenNotPaused {
        Agent storage agent = agents[msg.sender];
        if (agent.activeTasksCount > 0) {
            revert("Agent has active tasks, cannot deregister yet.");
        }
        agent.isRegistered = false; // Mark as not registered for new tasks
        agent.deregisterTimestamp = block.timestamp;
        emit AgentDeregistered(msg.sender, block.timestamp);
    }

    /**
     * @dev Allows a deregistered agent to reclaim their stake after `AGENT_STAKE_COOLDOWN_PERIOD`
     *      and if they have no active tasks.
     */
    function reclaimAgentStake() external nonReentrant {
        Agent storage agent = agents[msg.sender];
        if (agent.isRegistered || agent.deregisterTimestamp == 0) {
            revert("Agent is not deregistered or not eligible.");
        }
        if (agent.activeTasksCount > 0) {
            revert("Agent still has active tasks.");
        }
        if (block.timestamp < agent.deregisterTimestamp + AGENT_STAKE_COOLDOWN_PERIOD) {
            revert(TaskNotDueForStakeReclaim());
        }
        if (agent.stake == 0) revert NothingToWithdraw();

        uint256 amount = agent.stake;
        agent.stake = 0;

        (bool success, ) = msg.sender.call{value: amount}("");
        if (!success) {
            agent.stake = amount; // Refund if transfer fails
            revert("Failed to reclaim agent stake.");
        }
        emit AgentStakeReclaimed(msg.sender, amount);
    }

    /**
     * @dev Allows the owner (or a dispute resolution mechanism) to slash an agent's stake.
     *      This is typically used as a penalty for failed tasks or malicious behavior.
     * @param _agent The address of the agent whose stake is to be slashed.
     * @param _amount The amount of stake to slash.
     */
    function slashAgentStake(address _agent, uint256 _amount) external onlyOwner whenNotPaused {
        Agent storage agent = agents[_agent];
        // Allow slashing for both registered and deregistered agents if stake is still held
        if (!agent.isRegistered && agent.deregisterTimestamp == 0 && agent.stake == 0) revert AgentNotRegistered();
        if (agent.stake < _amount) revert InsufficientStake();

        agent.stake = agent.stake.sub(_amount);
        _platformFeesAccumulated = _platformFeesAccumulated.add(_amount); // Slashed stake goes to platform fees.

        // Decrease reputation, example: 10 reputation points per ETH slashed
        _decreaseAgentReputation(_agent, _amount.div(1 ether).mul(10));

        emit AgentStakeSlashed(_agent, _amount, msg.sender);
    }

    // --- III. Task Management (Requesters Posting & Managing Tasks) ---

    /**
     * @dev Allows a requester to create a new AI task, defining its parameters and depositing the reward.
     * @param _taskDescription String describing the task (e.g., IPFS CID for detailed spec).
     * @param _dataCID IPFS CID of the input data for the task.
     * @param _requiredCapabilities Array of hashes of capabilities required from an agent.
     * @param _reward The amount of ETH to be paid to the agent upon successful completion.
     * @param _challengeWindow The duration in seconds for which the requester can challenge a completion claim.
     * @param _minAgentReputation Minimum reputation an agent must have to be selected for this task.
     */
    function createTask(
        string memory _taskDescription,
        bytes32 _dataCID,
        bytes32[] calldata _requiredCapabilities,
        uint256 _reward,
        uint256 _challengeWindow,
        uint256 _minAgentReputation
    ) external payable nonReentrant whenNotPaused returns (uint256) {
        if (_reward == 0) revert("Task reward cannot be zero.");
        if (msg.value < _reward) revert("Insufficient funds sent for task reward.");
        if (_challengeWindow == 0) revert("Challenge window must be greater than zero.");

        uint256 taskId = _nextTaskId++;
        tasks[taskId] = Task({
            requester: msg.sender,
            selectedAgent: address(0),
            rewardAmount: _reward,
            taskDescription: _taskDescription,
            dataCID: _dataCID,
            requiredCapabilities: _requiredCapabilities,
            outputCID: bytes32(0),
            proofIdentifier: bytes32(0),
            minAgentReputation: _minAgentReputation,
            submissionTimestamp: 0,
            challengeWindowEnd: 0,
            status: TaskStatus.OpenForBids,
            creationTimestamp: block.timestamp,
            selectedBidAmount: 0,
            platformFeeCollected: 0
        });

        emit TaskCreated(taskId, msg.sender, _reward, _requiredCapabilities);
        return taskId;
    }

    /**
     * @dev Allows a registered agent to submit a bid for an open task.
     *      Agent's capabilities and reputation are checked.
     * @param _taskId The ID of the task to bid on.
     * @param _bidAmount The amount the agent is willing to accept for the task. Must be <= `rewardAmount`.
     */
    function bidForTask(uint256 _taskId, uint256 _bidAmount) external onlyAgent(msg.sender) whenNotPaused {
        Task storage task = tasks[_taskId];
        if (task.requester == address(0)) revert TaskNotFound();
        if (task.status != TaskStatus.OpenForBids) revert TaskNotInOpenState();
        if (_bidAmount == 0 || _bidAmount > task.rewardAmount) revert InvalidBidAmount();
        if (agentReputation[msg.sender] < task.minAgentReputation) revert MinimumReputationNotMet();
        if (_taskBids[_taskId][msg.sender] != 0) revert AgentAlreadyBid();

        Agent storage agent = agents[msg.sender];
        
        // Check if agent possesses all required capabilities
        for (uint256 i = 0; i < task.requiredCapabilities.length; i++) {
            bool foundCapability = false;
            for (uint256 j = 0; j < agent.capabilities.length; j++) {
                if (task.requiredCapabilities[i] == agent.capabilities[j]) {
                    foundCapability = true;
                    break;
                }
            }
            if (!foundCapability) {
                revert AgentDoesNotPossessAllRequiredCapabilities();
            }
        }

        _taskBids[_taskId][msg.sender] = _bidAmount;
        _taskBidders[_taskId].push(msg.sender);

        emit TaskBid(_taskId, msg.sender, _bidAmount);
    }

    /**
     * @dev Allows the requester to select an agent from the submitted bids for a task.
     * @param _taskId The ID of the task.
     * @param _agentAddress The address of the agent to select.
     */
    function selectAgentForTask(uint256 _taskId, address _agentAddress) external onlyRequester(_taskId) whenNotPaused {
        Task storage task = tasks[_taskId];
        if (task.status != TaskStatus.OpenForBids) revert TaskNotInOpenState();
        if (task.selectedAgent != address(0)) revert TaskAlreadyAssigned();
        if (_taskBids[_taskId][_agentAddress] == 0) revert("Agent has not bid on this task.");
        if (!agents[_agentAddress].isRegistered) revert AgentNotRegistered();

        uint256 bidAmount = _taskBids[_taskId][_agentAddress];

        task.selectedAgent = _agentAddress;
        task.selectedBidAmount = bidAmount;
        task.status = TaskStatus.Assigned;
        agents[_agentAddress].activeTasksCount++;
        agentActiveTasks[_agentAddress].push(_taskId);

        emit AgentSelected(_taskId, msg.sender, _agentAddress, bidAmount);
    }

    /**
     * @dev Allows the selected agent to claim completion of an assigned task.
     *      Requires a proof identifier (e.g., ZKP hash) and the output data CID.
     * @param _taskId The ID of the completed task.
     * @param _proofIdentifier A hash or ID referencing the off-chain verifiable proof of computation.
     * @param _outputCID IPFS CID of the output data generated by the agent.
     */
    function submitTaskCompletionClaim(uint256 _taskId, bytes32 _proofIdentifier, bytes32 _outputCID) external onlyAgent(msg.sender) whenNotPaused {
        Task storage task = tasks[_taskId];
        if (task.requester == address(0)) revert TaskNotFound();
        if (task.selectedAgent != msg.sender) revert AgentNotSelectedForTask();
        if (task.status != TaskStatus.Assigned) revert InvalidTaskStatus();

        task.outputCID = _outputCID;
        task.proofIdentifier = _proofIdentifier;
        task.submissionTimestamp = block.timestamp;
        task.challengeWindowEnd = block.timestamp + tasks[_taskId].challengeWindow;
        task.status = TaskStatus.AgentClaimedCompletion;

        emit TaskCompletionClaimed(_taskId, msg.sender, _proofIdentifier, _outputCID);
    }

    /**
     * @dev Allows the requester to challenge a claimed task completion within the challenge window.
     *      This moves the task into a dispute resolution state.
     * @param _taskId The ID of the task to challenge.
     */
    function challengeTaskCompletion(uint256 _taskId) external onlyRequester(_taskId) whenNotPaused {
        Task storage task = tasks[_taskId];
        if (task.status != TaskStatus.AgentClaimedCompletion) revert InvalidTaskStatus();
        if (block.timestamp > task.challengeWindowEnd) revert("Challenge window has closed.");

        task.status = TaskStatus.Challenged;
        emit TaskCompletionChallenged(_taskId, msg.sender);
    }

    /**
     * @dev Resolves a dispute for a challenged task. This function is callable by the owner
     *      (representing a dispute resolution mechanism like a DAO or oracle).
     *      It determines whether the agent or requester wins the dispute, affecting fund distribution and reputation.
     * @param _taskId The ID of the disputed task.
     * @param _agentWins True if the agent wins the dispute, false if the requester wins.
     */
    function resolveDispute(uint256 _taskId, bool _agentWins) external onlyOwner nonReentrant whenNotPaused {
        Task storage task = tasks[_taskId];
        if (task.requester == address(0)) revert TaskNotFound();
        if (task.status != TaskStatus.Challenged) revert DisputeNotPending();
        if (task.selectedAgent == address(0)) revert TaskNotAssigned();

        address agentAddress = task.selectedAgent;
        uint256 agentPayment = task.selectedBidAmount;

        // Platform fee calculated on the agent's actual payment.
        uint256 fee = agentPayment.mul(platformFeeRate).div(10000);
        task.platformFeeCollected = fee;

        if (_agentWins) {
            _platformFeesAccumulated = _platformFeesAccumulated.add(fee);
            _increaseAgentReputation(agentAddress, 5); // Example: 5 reputation points for winning
            task.status = TaskStatus.Completed;
        } else {
            _decreaseAgentReputation(agentAddress, 10); // Example: 10 reputation points for losing
            task.status = TaskStatus.Failed;
        }

        // Mark task as settled for the agent regardless of outcome
        _removeTaskFromAgentActiveTasks(agentAddress, _taskId);

        emit DisputeResolved(_taskId, _agentWins, msg.sender);
    }

    /**
     * @dev Allows the requester to confirm satisfactory completion of a task.
     *      This releases the funds (minus platform fees) to the agent and updates reputation.
     * @param _taskId The ID of the task to confirm.
     */
    function confirmTaskCompletion(uint256 _taskId) external onlyRequester(_taskId) nonReentrant whenNotPaused {
        Task storage task = tasks[_taskId];
        if (task.status != TaskStatus.AgentClaimedCompletion) revert InvalidTaskStatus();
        if (block.timestamp < task.challengeWindowEnd) revert("Cannot confirm before challenge window closes.");
        if (task.selectedAgent == address(0)) revert TaskNotAssigned();

        address agentAddress = task.selectedAgent;
        uint256 agentPayment = task.selectedBidAmount;

        // Calculate platform fee
        uint256 fee = agentPayment.mul(platformFeeRate).div(10000);
        task.platformFeeCollected = fee;
        _platformFeesAccumulated = _platformFeesAccumulated.add(fee);

        // Increase agent reputation
        _increaseAgentReputation(agentAddress, 3); // Example: 3 reputation points for successful completion

        task.status = TaskStatus.Completed;
        // Mark task as settled for the agent
        _removeTaskFromAgentActiveTasks(agentAddress, _taskId);

        emit TaskConfirmed(_taskId, msg.sender, agentAddress);
    }

    /**
     * @dev Allows the requester to cancel a task, but only if it's still in the `OpenForBids` state.
     *      Funds are returned to the requester.
     * @param _taskId The ID of the task to cancel.
     */
    function cancelTask(uint256 _taskId) external onlyRequester(_taskId) nonReentrant whenNotPaused {
        Task storage task = tasks[_taskId];
        if (task.status != TaskStatus.OpenForBids) revert TaskCannotBeCancelled();

        task.status = TaskStatus.Cancelled;
        // Funds remain in contract, available for withdrawal by requester via `withdrawTaskFundsByRequester`
        emit TaskCancelled(_taskId, msg.sender);
    }

    /**
     * @dev Allows the original requester to withdraw their deposited funds for a task.
     *      Funds are available if the task was cancelled, failed (dispute lost by agent), or the agent's bid was less than the initial reward.
     * @param _taskId The ID of the task.
     */
    function withdrawTaskFundsByRequester(uint256 _taskId) external nonReentrant {
        Task storage task = tasks[_taskId];
        if (task.requester != msg.sender) revert Unauthorized();
        if (task.rewardAmount == 0) revert NothingToWithdraw(); // Funds already accounted for or withdrawn

        uint256 amountToWithdraw = 0;
        if (task.status == TaskStatus.Cancelled || task.status == TaskStatus.Failed) {
            amountToWithdraw = task.rewardAmount;
        } else if (task.status == TaskStatus.Completed && task.selectedAgent != address(0)) {
            // If task completed, requester gets back the difference between initial reward and selected agent's bid.
            amountToWithdraw = task.rewardAmount.sub(task.selectedBidAmount);
        } else {
            revert("Funds not available for withdrawal for this task status.");
        }

        if (amountToWithdraw == 0) revert NothingToWithdraw();

        // Zero out the rewardAmount to prevent double withdrawals for this portion
        // The remaining `selectedBidAmount` will be handled by the agent's withdrawal.
        task.rewardAmount = task.rewardAmount.sub(amountToWithdraw);

        (bool success, ) = msg.sender.call{value: amountToWithdraw}("");
        if (!success) {
            task.rewardAmount = task.rewardAmount.add(amountToWithdraw); // Refund if transfer fails
            revert("Failed to withdraw funds.");
        }
        emit FundsWithdrawn(msg.sender, amountToWithdraw, "Requester Task Funds");
    }

    /**
     * @dev Allows the selected agent to withdraw their payment for a successfully completed or resolved task.
     * @param _taskId The ID of the task.
     */
    function withdrawTaskFundsByAgent(uint256 _taskId) external nonReentrant {
        Task storage task = tasks[_taskId];
        if (task.selectedAgent != msg.sender) revert Unauthorized();
        if (task.selectedBidAmount == 0) revert NothingToWithdraw(); // Agent's portion already withdrawn or not set

        if (task.status != TaskStatus.Completed) {
            revert("Task not yet completed or dispute not resolved in agent's favor.");
        }

        uint256 paymentToAgent = task.selectedBidAmount.sub(task.platformFeeCollected);
        if (paymentToAgent == 0) revert NothingToWithdraw();

        // Mark agent's portion as withdrawn.
        task.selectedBidAmount = 0;

        (bool success, ) = msg.sender.call{value: paymentToAgent}("");
        if (!success) {
            task.selectedBidAmount = paymentToAgent; // Refund if transfer fails
            revert("Failed to withdraw agent payment.");
        }
        emit FundsWithdrawn(msg.sender, paymentToAgent, "Agent Task Payment");
    }

    // --- IV. Reputation & Dynamic Features ---

    /**
     * @dev Returns the current reputation score of an agent.
     * @param _agent The address of the agent.
     * @return The agent's reputation score.
     */
    function getAgentReputation(address _agent) external view returns (uint256) {
        return agentReputation[_agent];
    }

    /**
     * @dev Internal function to increase an agent's reputation.
     * @param _agent The agent's address.
     * @param _points The number of reputation points to add.
     */
    function _increaseAgentReputation(address _agent, uint256 _points) internal {
        agentReputation[_agent] = agentReputation[_agent].add(_points);
        emit AgentReputationIncreased(_agent, _points);
    }

    /**
     * @dev Internal function to decrease an agent's reputation.
     * @param _agent The agent's address.
     * @param _points The number of reputation points to subtract.
     */
    function _decreaseAgentReputation(address _agent, uint256 _points) internal {
        agentReputation[_agent] = agentReputation[_agent].sub(_points > agentReputation[_agent] ? agentReputation[_agent] : _points);
        emit AgentReputationDecreased(_agent, _points);
    }

    /**
     * @dev Owner/DAO can manually increase an agent's reputation.
     *      Useful for rewarding exceptional off-chain performance or community contributions.
     * @param _agent The address of the agent.
     * @param _points The number of reputation points to add.
     */
    function increaseAgentReputation(address _agent, uint256 _points) external onlyOwner whenNotPaused {
        _increaseAgentReputation(_agent, _points);
    }

    /**
     * @dev Owner/DAO can manually decrease an agent's reputation.
     *      Useful for penalizing verified off-chain misconduct not directly tied to a task dispute.
     * @param _agent The address of the agent.
     * @param _points The number of reputation points to subtract.
     */
    function decreaseAgentReputation(address _agent, uint256 _points) external onlyOwner whenNotPaused {
        _decreaseAgentReputation(_agent, _points);
    }

    // --- Internal Helpers ---

    /**
     * @dev Removes a task ID from an agent's active tasks list and decrements the counter.
     * @param _agent The agent's address.
     * @param _taskId The task ID to remove.
     */
    function _removeTaskFromAgentActiveTasks(address _agent, uint256 _taskId) internal {
        Agent storage agent = agents[_agent];
        // It's possible for activeTasksCount to be 0 if agent was deregistered/slashed
        // and tasks were resolved without removing from this list earlier, or if it's a new agent
        // with no active tasks. Ensure robust check.
        if (agent.activeTasksCount == 0) return; // No tasks to remove

        uint256[] storage tasksList = agentActiveTasks[_agent];
        for (uint256 i = 0; i < tasksList.length; i++) {
            if (tasksList[i] == _taskId) {
                // Swap with the last element and pop to maintain O(1) average time complexity for deletion
                tasksList[i] = tasksList[tasksList.length - 1];
                tasksList.pop();
                agent.activeTasksCount--;
                return;
            }
        }
        // If the task was not found in the list, it's not a critical error for task resolution
        // but might indicate an inconsistency. For this implementation, we simply return.
    }

    // Fallback function to receive Ether
    receive() external payable {}
}
```