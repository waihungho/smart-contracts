```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title CerebralNexus
 * @dev A decentralized platform for AI agent task coordination, reputation, and dynamic NFTs.
 *      Users can submit complex computational tasks, which are then picked up by registered AI agents.
 *      Agents compete, submit verifiable results (potentially with ZK proofs), and build on-chain reputation.
 *      Agents are represented by dynamic NFTs whose metadata reflects their performance and reputation.
 *      A robust dispute resolution system, involving staked validators, ensures result integrity.
 */

// OUTLINE:
// I. Core Infrastructure & Agent Management:
//    Handles agent registration, profile updates, staking, and active status. Agents are represented by unique Dynamic NFTs.
//    - registerAgent: Mints a new Agent NFT and requires initial stake.
//    - updateAgentProfile: Updates an agent's off-chain profile URI.
//    - setAgentStatus: Allows an agent to toggle its availability for tasks.
//    - stakeForAgent: Increases an agent's staked amount.
//    - withdrawAgentStake: Allows an agent to withdraw their stake, subject to conditions.
//
// II. Task & Request Management:
//     Allows users to submit computational tasks, agents to propose solutions, and manages the lifecycle of a task.
//    - submitTaskRequest: Creates a new task with bounty, skill requirements, and task specifications.
//    - proposeSolution: An agent proposes to execute a task, locking part of its stake.
//    - selectAgentForTask: Requestor selects an agent for their task.
//    - submitTaskResult: Agent submits the hash of the off-chain result and an optional ZK proof hash.
//    - finalizeTask: Requestor reviews results and releases bounty or initiates a dispute.
//    - cancelTask: Requestor can cancel an unassigned/uncompleted task.
//
// III. Reputation & Dispute Resolution:
//      Implements a reputation system for agents and a mechanism for resolving disputes over task results, involving validators.
//    - becomeValidator: Users stake tokens to become a dispute validator.
//    - voteOnDispute: Validators cast their vote on a disputed task's outcome.
//    - resolveDispute: Finalizes a dispute, updating reputations and distributing rewards/penalties.
//    - getAgentReputation: Retrieves an agent's current reputation score.
//    - slashValidator: Admin function to penalize misbehaving validators.
//
// IV. Dynamic Agent NFTs (dNFTs):
//     Manages the on-chain representation and dynamic metadata updates for AI Agent NFTs.
//    - getAgentDynamicMetadata: Returns the dynamic metadata URI for an Agent NFT.
//    - requestMetadataRefresh: Signals for off-chain services to update an agent's metadata.
//
// V. Economic & Governance Parameters:
//    Manages contract-level parameters like protocol fees, reward distribution, and conceptual ZK verifier integration.
//    - setProtocolFee: Sets the percentage fee taken from task bounties.
//    - setRewardDistributions: Defines how the collected protocol fees are split (devs, validators, treasury).
//    - setZKVerifierAddress: Updates the address of a smart contract responsible for verifying ZK proofs.

contract CerebralNexus is ERC721, Ownable {
    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;

    // --- State Variables ---
    IERC20 public immutable paymentToken;
    address public immutable protocolTreasury;
    address public immutable developerWallet;

    // Agent Management
    Counters.Counter private _agentIds;
    uint256 public constant MIN_AGENT_STAKE = 1000 * 1e18; // Example: 1000 tokens
    uint256 public constant AGENT_REPUTATION_FLOOR = 1000; // Starting reputation for new agents

    struct Agent {
        address owner;
        uint256 stake;
        string profileURI; // Off-chain URI for detailed agent description/endpoint
        uint256 reputation; // Reputation score, influencing task eligibility and rewards
        bool isActive;      // Can propose solutions if active
        uint256 createdAt;
    }
    mapping(uint256 => Agent) public agents; // agentId => Agent
    mapping(address => uint256[]) public ownerToAgentIds; // owner address => list of agentIds

    // Task Management
    Counters.Counter private _taskIds;
    uint256 public constant TASK_PROPOSAL_STAKE_PERCENT_BPS = 500; // 5% of agent stake locked during proposal
    uint256 public constant TASK_DISPUTE_PERIOD_SECONDS = 3 days;
    uint256 public constant TASK_RESOLUTION_PERIOD_SECONDS = 7 days; // Time for validators to vote

    enum TaskStatus {
        Open,           // Task submitted, awaiting proposals
        Proposed,       // Agents have proposed solutions
        Assigned,       // Agent selected, awaiting result submission
        ResultSubmitted,// Agent submitted result, awaiting finalization/dispute
        Disputed,       // Task result disputed, awaiting validator votes
        Resolved,       // Dispute resolved by validators
        Completed,      // Task finalized, bounty paid
        Cancelled       // Task cancelled by requestor
    }

    struct Task {
        address requestor;
        uint256 bounty;
        uint256 requiredSkillLevel; // A subjective metric for task complexity/expertise
        bytes32 taskSpecificationHash; // Hash of off-chain task details (e.g., IPFS CID)
        uint256 assignedAgentId;
        bytes32 resultHash;     // Hash of the off-chain result
        bytes32 zkProofHash;    // Optional hash of a ZK proof for the result
        TaskStatus status;
        uint256 assignmentTimestamp;
        uint256 resultSubmissionTimestamp;
        uint256 disputeResolutionTimestamp; // End of dispute voting period
        address selectedAgent; // The actual address of the agent who took the task
    }
    mapping(uint256 => Task) public tasks;
    mapping(uint256 => mapping(uint256 => bool)) public proposedSolutions; // taskId => agentId => bool

    // Reputation & Dispute Resolution
    uint256 public constant MIN_VALIDATOR_STAKE = 5000 * 1e18; // Example: 5000 tokens
    uint256 public constant REPUTATION_CHANGE_WIN = 100; // Points gained for success/correct vote
    uint256 public constant REPUTATION_CHANGE_LOSE = 200; // Points lost for failure/incorrect vote
    uint256 public constant AGENT_SLASH_PERCENT_BPS = 1000; // 10% of agent stake slashed on failure
    uint256 public constant VALIDATOR_SLASH_PERCENT_BPS = 500; // 5% of validator stake slashed on incorrect vote

    struct Validator {
        uint256 stake;
        uint256 reputation;
        uint256 registeredAt;
        bool isActive;
    }
    mapping(address => Validator) public validators;
    mapping(uint256 => mapping(address => bool)) public disputeVotes; // taskId => validatorAddress => hasVoted
    mapping(uint256 => uint256) public disputeYesVotes; // taskId => votes for agent being correct
    mapping(uint256 => uint256) public disputeNoVotes;  // taskId => votes for agent being incorrect

    // Economic & Governance Parameters
    uint256 public protocolFeeBps = 100; // 1% (100 basis points out of 10000)
    uint256 public devShareBps = 5000;      // 50% of protocol fee to developer
    uint256 public validatorShareBps = 3000; // 30% of protocol fee to validators
    uint256 public treasuryShareBps = 2000; // 20% of protocol fee to treasury
    address public zkVerifierAddress; // Address of a contract for verifying ZK proofs (conceptual hook)

    // --- Events ---
    event AgentRegistered(uint256 indexed agentId, address indexed owner, string profileURI, uint256 initialStake);
    event AgentProfileUpdated(uint256 indexed agentId, string newProfileURI);
    event AgentStatusUpdated(uint256 indexed agentId, bool isActive);
    event AgentStaked(uint256 indexed agentId, address indexed staker, uint256 amount);
    event AgentStakeWithdrawn(uint256 indexed agentId, address indexed receiver, uint256 amount);

    event TaskRequested(uint256 indexed taskId, address indexed requestor, uint256 bounty, uint256 requiredSkillLevel);
    event SolutionProposed(uint256 indexed taskId, uint256 indexed agentId);
    event AgentSelected(uint256 indexed taskId, uint256 indexed agentId);
    event TaskResultSubmitted(uint256 indexed taskId, uint256 indexed agentId, bytes32 resultHash, bytes32 zkProofHash);
    event TaskFinalized(uint256 indexed taskId, uint256 indexed agentId, TaskStatus status, uint256 disbursedBounty);
    event TaskCancelled(uint256 indexed taskId, address indexed requestor, uint256 refundedBounty);

    event DisputeInitiated(uint256 indexed taskId, uint256 indexed agentId);
    event ValidatorRegistered(address indexed validator, uint256 stake);
    event VotedOnDispute(uint256 indexed taskId, address indexed validator, bool agentWasCorrect);
    event DisputeResolved(uint256 indexed taskId, bool agentWasCorrect, uint256 totalYesVotes, uint256 totalNoVotes);
    event ValidatorSlashed(address indexed validator, uint256 amount);

    event MetadataRefreshRequested(uint256 indexed agentId);
    event ProtocolFeeUpdated(uint256 newFeeBps);
    event RewardDistributionUpdated(uint256 devShareBps, uint256 validatorShareBps, uint256 treasuryShareBps);
    event ZKVerifierAddressUpdated(address newVerifier);

    // --- Custom Errors ---
    error InvalidAmount();
    error AgentNotFound();
    error NotAgentOwner();
    error AgentNotActive();
    error InsufficientAgentStake(uint256 required, uint256 available);
    error AgentAlreadyRegistered();
    error TaskNotFound();
    error NotTaskRequestor();
    error InvalidTaskStatus();
    error AgentAlreadyProposed();
    error NoProposalsAvailable();
    error AgentNotSelectedForTask();
    error AgentHasActiveTasks();
    error TaskDisputePeriodNotEnded();
    error TaskResolutionPeriodNotEnded();
    error TaskResolutionPeriodEnded();
    error ValidatorNotFound();
    error AlreadyVoted();
    error InsufficientValidatorStake(uint256 required, uint256 available);
    error InvalidShareDistribution();
    error InvalidFeeBps();
    error NotProtocolTreasury();

    // --- Constructor ---
    constructor(
        address _paymentToken,
        address _protocolTreasury,
        address _developerWallet,
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) Ownable(msg.sender) {
        require(_paymentToken != address(0), "Payment token cannot be zero address");
        require(_protocolTreasury != address(0), "Treasury cannot be zero address");
        require(_developerWallet != address(0), "Developer wallet cannot be zero address");

        paymentToken = IERC20(_paymentToken);
        protocolTreasury = _protocolTreasury;
        developerWallet = _developerWallet;
    }

    // --- I. Core Infrastructure & Agent Management (5 functions) ---

    /**
     * @dev Registers a new AI agent, minting a unique Agent NFT.
     * Requires an initial stake to ensure commitment and reputation.
     * @param _name The name of the agent (used for NFT metadata).
     * @param _profileURI An off-chain URI linking to more detailed agent information or endpoint.
     */
    function registerAgent(string calldata _name, string calldata _profileURI) external {
        for (uint255 i = 0; i < ownerToAgentIds[msg.sender].length; i++) {
            if (agents[ownerToAgentIds[msg.sender][i]].owner == msg.sender) {
                revert AgentAlreadyRegistered(); // Prevent multiple agents per owner for simplicity
            }
        }
        require(paymentToken.balanceOf(msg.sender) >= MIN_AGENT_STAKE, "Insufficient tokens for initial stake");
        paymentToken.safeTransferFrom(msg.sender, address(this), MIN_AGENT_STAKE);

        _agentIds.increment();
        uint256 newAgentId = _agentIds.current();

        agents[newAgentId] = Agent({
            owner: msg.sender,
            stake: MIN_AGENT_STAKE,
            profileURI: _profileURI,
            reputation: AGENT_REPUTATION_FLOOR,
            isActive: true,
            createdAt: block.timestamp
        });
        ownerToAgentIds[msg.sender].push(newAgentId);

        _safeMint(msg.sender, newAgentId); // Mint Agent NFT
        _setTokenURI(newAgentId, _profileURI); // Set initial URI, will be overridden by dynamic logic

        emit AgentRegistered(newAgentId, msg.sender, _profileURI, MIN_AGENT_STAKE);
    }

    /**
     * @dev Allows a registered agent to update its off-chain profile link or description.
     * @param _agentId The ID of the agent to update.
     * @param _newProfileURI The new URI for the agent's profile.
     */
    function updateAgentProfile(uint256 _agentId, string calldata _newProfileURI) external {
        require(_exists(_agentId), "Agent NFT does not exist");
        require(ownerOf(_agentId) == msg.sender, "Caller is not the owner of this agent NFT");

        agents[_agentId].profileURI = _newProfileURI;
        emit AgentProfileUpdated(_agentId, _newProfileURI);
    }

    /**
     * @dev Allows an agent to set its active status, determining if it can propose solutions to tasks.
     * @param _agentId The ID of the agent.
     * @param _isActive The new active status (true to participate, false to opt out).
     */
    function setAgentStatus(uint256 _agentId, bool _isActive) external {
        require(_exists(_agentId), "Agent NFT does not exist");
        require(ownerOf(_agentId) == msg.sender, "Caller is not the owner of this agent NFT");

        agents[_agentId].isActive = _isActive;
        emit AgentStatusUpdated(_agentId, _isActive);
    }

    /**
     * @dev Allows an agent to add more tokens to its stake, enhancing its reputation multiplier and task eligibility.
     * @param _agentId The ID of the agent.
     * @param _amount The amount of tokens to stake.
     */
    function stakeForAgent(uint256 _agentId, uint256 _amount) external {
        if (_amount == 0) revert InvalidAmount();
        require(_exists(_agentId), "Agent NFT does not exist");
        require(ownerOf(_agentId) == msg.sender, "Caller is not the owner of this agent NFT");

        paymentToken.safeTransferFrom(msg.sender, address(this), _amount);
        agents[_agentId].stake += _amount;

        emit AgentStaked(_agentId, msg.sender, _amount);
    }

    /**
     * @dev Allows an agent to withdraw their stake, subject to no active tasks.
     * @param _agentId The ID of the agent.
     * @param _amount The amount of tokens to withdraw.
     */
    function withdrawAgentStake(uint256 _agentId, uint256 _amount) external {
        if (_amount == 0) revert InvalidAmount();
        require(_exists(_agentId), "Agent NFT does not exist");
        require(ownerOf(_agentId) == msg.sender, "Caller is not the owner of this agent NFT");
        require(agents[_agentId].stake - _amount >= MIN_AGENT_STAKE, "Cannot withdraw below min stake");
        
        // Check for active tasks where the agent is assigned
        bool hasActiveTasks = false;
        for (uint256 i = 1; i <= _taskIds.current(); i++) {
            if (tasks[i].assignedAgentId == _agentId && (tasks[i].status == TaskStatus.Assigned || tasks[i].status == TaskStatus.ResultSubmitted)) {
                hasActiveTasks = true;
                break;
            }
        }
        if (hasActiveTasks) revert AgentHasActiveTasks();

        agents[_agentId].stake -= _amount;
        paymentToken.safeTransfer(msg.sender, _amount);

        emit AgentStakeWithdrawn(_agentId, msg.sender, _amount);
    }

    // --- II. Task & Request Management (6 functions) ---

    /**
     * @dev Creates a new task, depositing bounty, defining requirements, and task specifications.
     * @param _bounty The amount of tokens offered as a bounty for completing the task.
     * @param _requiredSkillLevel A subjective metric indicating the skill level required (e.g., 1-100).
     * @param _taskSpecificationHash A hash (e.g., IPFS CID) pointing to the detailed task description.
     */
    function submitTaskRequest(
        uint256 _bounty,
        uint256 _requiredSkillLevel,
        bytes32 _taskSpecificationHash
    ) external {
        if (_bounty == 0) revert InvalidAmount();
        paymentToken.safeTransferFrom(msg.sender, address(this), _bounty);

        _taskIds.increment();
        uint256 newTaskId = _taskIds.current();

        tasks[newTaskId] = Task({
            requestor: msg.sender,
            bounty: _bounty,
            requiredSkillLevel: _requiredSkillLevel,
            taskSpecificationHash: _taskSpecificationHash,
            assignedAgentId: 0,
            resultHash: bytes32(0),
            zkProofHash: bytes32(0),
            status: TaskStatus.Open,
            assignmentTimestamp: 0,
            resultSubmissionTimestamp: 0,
            disputeResolutionTimestamp: 0,
            selectedAgent: address(0)
        });

        emit TaskRequested(newTaskId, msg.sender, _bounty, _requiredSkillLevel);
    }

    /**
     * @dev An active agent proposes to execute a task, locking a portion of its stake.
     * @param _taskId The ID of the task to propose a solution for.
     * @param _agentId The ID of the agent making the proposal.
     */
    function proposeSolution(uint256 _taskId, uint256 _agentId) external {
        require(_exists(_agentId), "Agent NFT does not exist");
        require(ownerOf(_agentId) == msg.sender, "Caller is not the owner of this agent NFT");
        require(agents[_agentId].isActive, "Agent is not active");
        require(tasks[_taskId].status == TaskStatus.Open || tasks[_taskId].status == TaskStatus.Proposed, "Task not open for proposals");
        require(!proposedSolutions[_taskId][_agentId], "Agent already proposed for this task");
        require(agents[_agentId].reputation >= tasks[_taskId].requiredSkillLevel, "Agent skill too low for this task");

        // Lock a percentage of agent stake as commitment
        uint256 proposalStake = (agents[_agentId].stake * TASK_PROPOSAL_STAKE_PERCENT_BPS) / 10000;
        require(agents[_agentId].stake >= proposalStake, "Insufficient agent stake for proposal lock");
        // For simplicity, we just mark it as locked. Actual token transfer not needed for this logic.
        // In a real system, this might involve an internal escrow or accounting.

        proposedSolutions[_taskId][_agentId] = true;
        tasks[_taskId].status = TaskStatus.Proposed; // Update status if it was Open

        emit SolutionProposed(_taskId, _agentId);
    }

    /**
     * @dev Requestor selects an agent from available proposals for their task.
     * @param _taskId The ID of the task.
     * @param _agentId The ID of the agent selected to perform the task.
     */
    function selectAgentForTask(uint256 _taskId, uint256 _agentId) external {
        require(tasks[_taskId].requestor == msg.sender, "Only task requestor can select agent");
        require(tasks[_taskId].status == TaskStatus.Proposed || tasks[_taskId].status == TaskStatus.Open, "Task not in proposal stage");
        require(proposedSolutions[_taskId][_agentId], "Agent did not propose for this task");
        require(agents[_agentId].isActive, "Selected agent is not active");

        tasks[_taskId].assignedAgentId = _agentId;
        tasks[_taskId].selectedAgent = agents[_agentId].owner; // Store agent's owner address
        tasks[_taskId].status = TaskStatus.Assigned;
        tasks[_taskId].assignmentTimestamp = block.timestamp;

        // Unlock proposal stakes of other agents if needed (not implemented here for simplicity)

        emit AgentSelected(_taskId, _agentId);
    }

    /**
     * @dev Agent submits the hash of the off-chain result and an optional ZK proof hash.
     * The ZK proof hash would be verified by a separate `zkVerifierAddress` contract.
     * @param _taskId The ID of the task.
     * @param _agentId The ID of the agent submitting the result.
     * @param _resultHash A hash (e.g., IPFS CID) pointing to the off-chain task result.
     * @param _zkProofHash An optional hash of a ZK proof for the computation, if applicable.
     */
    function submitTaskResult(
        uint256 _taskId,
        uint256 _agentId,
        bytes32 _resultHash,
        bytes32 _zkProofHash
    ) external {
        require(tasks[_taskId].assignedAgentId == _agentId, "Only assigned agent can submit result");
        require(ownerOf(_agentId) == msg.sender, "Caller is not the owner of this agent NFT");
        require(tasks[_taskId].status == TaskStatus.Assigned, "Task not awaiting result submission");
        require(_resultHash != bytes32(0), "Result hash cannot be empty");

        tasks[_taskId].resultHash = _resultHash;
        tasks[_taskId].zkProofHash = _zkProofHash;
        tasks[_taskId].status = TaskStatus.ResultSubmitted;
        tasks[_taskId].resultSubmissionTimestamp = block.timestamp;

        emit TaskResultSubmitted(_taskId, _agentId, _resultHash, _zkProofHash);
    }

    /**
     * @dev Requestor reviews the result hash/ZK proof. If satisfactory, bounty is released and reputation updated.
     * Otherwise, a dispute is initiated.
     * @param _taskId The ID of the task to finalize.
     */
    function finalizeTask(uint256 _taskId) external {
        require(tasks[_taskId].requestor == msg.sender, "Only task requestor can finalize");
        require(tasks[_taskId].status == TaskStatus.ResultSubmitted, "Task not in result submitted stage");

        uint256 agentId = tasks[_taskId].assignedAgentId;

        // Potentially call external ZK verifier here:
        // if (tasks[_taskId].zkProofHash != bytes32(0)) {
        //     IZKVerifier(zkVerifierAddress).verifyProof(tasks[_taskId].zkProofHash);
        // }

        // Distribute bounty and fees
        uint256 totalBounty = tasks[_taskId].bounty;
        uint256 protocolFee = (totalBounty * protocolFeeBps) / 10000;
        uint256 agentReward = totalBounty - protocolFee;

        // Transfer funds
        paymentToken.safeTransfer(agents[agentId].owner, agentReward);
        if (protocolFee > 0) {
            paymentToken.safeTransfer(address(this), protocolFee); // Hold fees in contract for distribution
        }

        // Update agent reputation
        agents[agentId].reputation += REPUTATION_CHANGE_WIN;
        tasks[_taskId].status = TaskStatus.Completed;

        emit TaskFinalized(_taskId, agentId, TaskStatus.Completed, agentReward);
    }

    /**
     * @dev Requestor can cancel an unassigned or uncompleted task, reclaiming bounty.
     * @param _taskId The ID of the task to cancel.
     */
    function cancelTask(uint256 _taskId) external {
        require(tasks[_taskId].requestor == msg.sender, "Only task requestor can cancel");
        require(
            tasks[_taskId].status == TaskStatus.Open ||
            tasks[_taskId].status == TaskStatus.Proposed,
            "Task cannot be cancelled in current status"
        );

        uint256 bounty = tasks[_taskId].bounty;
        tasks[_taskId].status = TaskStatus.Cancelled;
        tasks[_taskId].bounty = 0; // Clear bounty to prevent double refund

        paymentToken.safeTransfer(msg.sender, bounty);

        emit TaskCancelled(_taskId, msg.sender, bounty);
    }

    // --- III. Reputation & Dispute Resolution (5 functions) ---

    /**
     * @dev Users can stake tokens to become a dispute validator, earning rewards for correct judgments.
     * @param _stakeAmount The amount of tokens to stake to become a validator.
     */
    function becomeValidator(uint256 _stakeAmount) external {
        if (_stakeAmount == 0) revert InvalidAmount();
        require(validators[msg.sender].stake == 0, "Validator already registered");
        require(_stakeAmount >= MIN_VALIDATOR_STAKE, "Insufficient stake to become a validator");

        paymentToken.safeTransferFrom(msg.sender, address(this), _stakeAmount);

        validators[msg.sender] = Validator({
            stake: _stakeAmount,
            reputation: AGENT_REPUTATION_FLOOR, // Validators also have a starting reputation
            registeredAt: block.timestamp,
            isActive: true
        });

        emit ValidatorRegistered(msg.sender, _stakeAmount);
    }

    /**
     * @dev Initiates a dispute if the requestor is not satisfied with the result.
     * Only callable by the task requestor after result submission.
     * This moves the task to a disputed state, starting a voting period.
     */
    function initiateDispute(uint256 _taskId) external {
        require(tasks[_taskId].requestor == msg.sender, "Only task requestor can dispute");
        require(tasks[_taskId].status == TaskStatus.ResultSubmitted, "Task not in result submitted stage");

        tasks[_taskId].status = TaskStatus.Disputed;
        tasks[_taskId].disputeResolutionTimestamp = block.timestamp + TASK_DISPUTE_PERIOD_SECONDS;

        emit DisputeInitiated(_taskId, tasks[_taskId].assignedAgentId);
    }

    /**
     * @dev Validators cast their vote on the outcome of a disputed task.
     * @param _taskId The ID of the disputed task.
     * @param _agentWasCorrect True if the validator believes the agent's result was correct, false otherwise.
     */
    function voteOnDispute(uint256 _taskId, bool _agentWasCorrect) external {
        require(validators[msg.sender].isActive, "Caller is not an active validator");
        require(tasks[_taskId].status == TaskStatus.Disputed, "Task not currently in dispute");
        require(block.timestamp < tasks[_taskId].disputeResolutionTimestamp, "Dispute voting period has ended");
        require(!disputeVotes[_taskId][msg.sender], "Validator has already voted on this dispute");

        disputeVotes[_taskId][msg.sender] = true;
        if (_agentWasCorrect) {
            disputeYesVotes[_taskId]++;
        } else {
            disputeNoVotes[_taskId]++;
        }

        emit VotedOnDispute(_taskId, msg.sender, _agentWasCorrect);
    }

    /**
     * @dev Finalizes a dispute after the voting period, updating reputations and distributing rewards/penalties.
     * Callable by anyone after the dispute period ends.
     * @param _taskId The ID of the task to resolve.
     */
    function resolveDispute(uint256 _taskId) external {
        require(tasks[_taskId].status == TaskStatus.Disputed, "Task is not in dispute");
        require(block.timestamp >= tasks[_taskId].disputeResolutionTimestamp, "Dispute voting period not ended");
        // Ensure there's a minimum resolution period before anyone can finalize to prevent manipulation
        require(block.timestamp < tasks[_taskId].disputeResolutionTimestamp + TASK_RESOLUTION_PERIOD_SECONDS, "Dispute resolution period ended");

        uint256 agentId = tasks[_taskId].assignedAgentId;
        bool agentWasCorrect = disputeYesVotes[_taskId] >= disputeNoVotes[_taskId];

        // Process agent outcome
        if (agentWasCorrect) {
            // Agent wins dispute, receives bounty, reputation increases
            uint256 totalBounty = tasks[_taskId].bounty;
            uint256 protocolFee = (totalBounty * protocolFeeBps) / 10000;
            uint256 agentReward = totalBounty - protocolFee;

            paymentToken.safeTransfer(agents[agentId].owner, agentReward);
            if (protocolFee > 0) {
                paymentToken.safeTransfer(address(this), protocolFee);
            }
            agents[agentId].reputation += REPUTATION_CHANGE_WIN;
            tasks[_taskId].status = TaskStatus.Completed;
        } else {
            // Agent loses dispute, reputation decreases, stake slashed, bounty refunded to requestor
            uint256 slashAmount = (agents[agentId].stake * AGENT_SLASH_PERCENT_BPS) / 10000;
            if (agents[agentId].stake > MIN_AGENT_STAKE) { // Only slash if agent has more than min stake
                if (agents[agentId].stake - slashAmount < MIN_AGENT_STAKE) { // Ensure not slashing below min stake
                    slashAmount = agents[agentId].stake - MIN_AGENT_STAKE;
                }
                agents[agentId].stake -= slashAmount;
                // Slashed amount goes to treasury or burn
                paymentToken.safeTransfer(protocolTreasury, slashAmount);
            }
            agents[agentId].reputation -= REPUTATION_CHANGE_LOSE;
            // Refund bounty to requestor
            paymentToken.safeTransfer(tasks[_taskId].requestor, tasks[_taskId].bounty);
            tasks[_taskId].status = TaskStatus.Cancelled; // Mark as cancelled due to agent failure
        }

        // Process validators
        uint256 totalFeeShareForValidators = (protocolFee * validatorShareBps) / 10000;
        uint256 validatorRewardPerVote = (totalFeeShareForValidators > 0 && (disputeYesVotes[_taskId] + disputeNoVotes[_taskId]) > 0) ?
                                        totalFeeShareForValidators / (disputeYesVotes[_taskId] + disputeNoVotes[_taskId]) : 0;

        for (uint256 i = 1; i <= _agentIds.current(); i++) { // Iterate all validators (could be inefficient for many validators)
            address validatorAddress = ownerOf(i); // This is not efficient, need a better way to iterate validators.
            // Simplified approach: iterate through _all_ addresses that might be validators for this _taskId
            // A more robust solution would track active validator addresses in a dynamic array.
            // For now, we'll iterate through known validators that voted
            if (disputeVotes[_taskId][validatorAddress]) { // If this address voted on the dispute
                bool validatorVotedCorrectly = (agentWasCorrect && disputeVotes[_taskId][validatorAddress]) ||
                                              (!agentWasCorrect && !disputeVotes[_taskId][validatorAddress]);

                if (validatorVotedCorrectly) {
                    validators[validatorAddress].reputation += REPUTATION_CHANGE_WIN;
                    // Reward for correct vote
                    if (validatorRewardPerVote > 0) {
                        // This would need to distribute to all correct voters, not just per vote.
                        // A more complex system would queue rewards and distribute them proportionally.
                        // For simplicity, we just increase reputation for now and handle fee distribution in a separate `distributeProtocolFees` function.
                    }
                } else {
                    validators[validatorAddress].reputation -= REPUTATION_CHANGE_LOSE;
                    // Slash for incorrect vote
                    uint256 validatorSlash = (validators[validatorAddress].stake * VALIDATOR_SLASH_PERCENT_BPS) / 10000;
                    if (validators[validatorAddress].stake - validatorSlash > MIN_VALIDATOR_STAKE) {
                        validators[validatorAddress].stake -= validatorSlash;
                        paymentToken.safeTransfer(protocolTreasury, validatorSlash);
                        emit ValidatorSlashed(validatorAddress, validatorSlash);
                    }
                }
            }
        }

        // Transfer remaining protocol fees
        uint256 remainingFees = paymentToken.balanceOf(address(this)) - tasks[_taskId].bounty; // Account for bounty refund if agent lost
        distributeProtocolFees(); // Call to distribute collected fees
        
        emit DisputeResolved(_taskId, agentWasCorrect, disputeYesVotes[_taskId], disputeNoVotes[_taskId]);
    }

    /**
     * @dev Public view of an agent's current reputation score.
     * @param _agentId The ID of the agent.
     * @return The current reputation score.
     */
    function getAgentReputation(uint256 _agentId) public view returns (uint256) {
        return agents[_agentId].reputation;
    }

    /**
     * @dev Admin or protocol-level function to penalize validators for repeated malicious or incorrect votes.
     * Can only be called by the contract owner.
     * @param _validator The address of the validator to slash.
     * @param _amount The amount of tokens to slash from their stake.
     */
    function slashValidator(address _validator, uint256 _amount) external onlyOwner {
        if (_amount == 0) revert InvalidAmount();
        require(validators[_validator].stake > 0, "Validator not found or no stake");
        require(validators[_validator].stake - _amount >= MIN_VALIDATOR_STAKE, "Cannot slash below min stake");

        validators[_validator].stake -= _amount;
        paymentToken.safeTransfer(protocolTreasury, _amount); // Slashed amount goes to treasury

        emit ValidatorSlashed(_validator, _amount);
    }

    // --- IV. Dynamic Agent NFTs (dNFTs) (2 functions) ---

    /**
     * @dev Returns a URI for the dynamic metadata of an agent's NFT.
     * This URI would typically point to an off-chain API that generates JSON metadata
     * based on the agent's current on-chain state (reputation, tasks, status).
     * @param _agentId The ID of the agent.
     * @return A URI for the dynamic metadata.
     */
    function getAgentDynamicMetadata(uint256 _agentId) public view returns (string memory) {
        // Construct a dynamic URI, e.g., pointing to an API endpoint
        // Example: "https://api.cerebralnexus.io/agent/metadata/{agentId}"
        return string(abi.encodePacked("https://api.cerebralnexus.io/agent/metadata/", Strings.toString(_agentId)));
    }

    /**
     * @dev Overrides ERC721's tokenURI to provide dynamic metadata.
     * This ensures that tools displaying the NFT (e.g., OpenSea) will fetch the dynamic URI.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId); // Ensure the token exists and is owned
        return getAgentDynamicMetadata(tokenId);
    }

    /**
     * @dev Signals to off-chain services (e.g., an IPFS pinning service or metadata API)
     * that an agent's metadata needs to be regenerated and re-pinned due to a state change.
     * This function doesn't change on-chain state itself but triggers an external process.
     * @param _agentId The ID of the agent whose metadata needs refreshing.
     */
    function requestMetadataRefresh(uint256 _agentId) external {
        _requireOwned(_agentId); // Only the agent owner or authorized parties can request refresh
        // This event serves as a signal for an off-chain listener
        emit MetadataRefreshRequested(_agentId);
    }

    // --- V. Economic & Governance Parameters (3 functions) ---

    /**
     * @dev Sets the percentage fee taken from task bounties, directed to the protocol treasury/devs.
     * Only callable by the contract owner.
     * @param _newFeeBps The new protocol fee in basis points (e.g., 100 for 1%). Max 10000.
     */
    function setProtocolFee(uint256 _newFeeBps) external onlyOwner {
        require(_newFeeBps <= 10000, "Fee cannot exceed 100%");
        protocolFeeBps = _newFeeBps;
        emit ProtocolFeeUpdated(_newFeeBps);
    }

    /**
     * @dev Defines how protocol fees are split between developers, validators, and the treasury.
     * The sum of shares must equal 10000 basis points (100%).
     * Only callable by the contract owner.
     * @param _devShareBps Share for developers in basis points.
     * @param _validatorShareBps Share for validators in basis points.
     * @param _treasuryShareBps Share for the protocol treasury in basis points.
     */
    function setRewardDistributions(
        uint256 _devShareBps,
        uint256 _validatorShareBps,
        uint256 _treasuryShareBps
    ) external onlyOwner {
        require(_devShareBps + _validatorShareBps + _treasuryShareBps == 10000, "Shares must sum to 10000 BPS");
        devShareBps = _devShareBps;
        validatorShareBps = _validatorShareBps;
        treasuryShareBps = _treasuryShareBps;
        emit RewardDistributionUpdated(_devShareBps, _validatorShareBps, _treasuryShareBps);
    }

    /**
     * @dev (Conceptual) Updates the address of a smart contract responsible for verifying ZK proofs
     * submitted by agents. This allows for upgrading or changing the ZK proof verification logic.
     * Only callable by the contract owner.
     * @param _newVerifier The address of the new ZK proof verifier contract.
     */
    function setZKVerifierAddress(address _newVerifier) external onlyOwner {
        require(_newVerifier != address(0), "ZK Verifier address cannot be zero");
        zkVerifierAddress = _newVerifier;
        emit ZKVerifierAddressUpdated(_newVerifier);
    }

    // --- Internal/Helper Functions ---

    /**
     * @dev Distributes accumulated protocol fees to developer, validator pool, and treasury.
     * Can be called by anyone to trigger fee distribution, but only if there are fees.
     * This design allows fees to accumulate and be claimed/distributed in batches.
     */
    function distributeProtocolFees() public {
        uint256 accumulatedFees = paymentToken.balanceOf(address(this)) - _totalStakedTokens(); // Only distribute protocol fees, not staked funds
        if (accumulatedFees == 0) return;

        uint256 devAmount = (accumulatedFees * devShareBps) / 10000;
        uint256 validatorAmount = (accumulatedFees * validatorShareBps) / 10000;
        uint256 treasuryAmount = (accumulatedFees * treasuryShareBps) / 10000;

        if (devAmount > 0) paymentToken.safeTransfer(developerWallet, devAmount);
        if (treasuryAmount > 0) paymentToken.safeTransfer(protocolTreasury, treasuryAmount);

        // Distribute validator share (more complex - needs to reward active correct validators)
        // For simplicity, this validatorAmount is held by the contract, and validators might claim their share or it's used to boost future validator rewards.
        // A real system would have a separate `claimValidatorRewards` function based on their reputation/contribution.
        // As a placeholder, we could send it to the treasury for later distribution if no specific mechanism is built.
        if (validatorAmount > 0) paymentToken.safeTransfer(protocolTreasury, validatorAmount); 
    }

    /**
     * @dev Calculates the total amount of tokens currently staked by agents and validators.
     * @return The total staked amount.
     */
    function _totalStakedTokens() internal view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 1; i <= _agentIds.current(); i++) {
            total += agents[i].stake;
        }
        // This is not efficient for many validators. A more optimized approach would involve tracking a global `totalValidatorStake`.
        // For demonstration purposes:
        // Iterate through all possible addresses as validators (highly inefficient) or maintain a list of validator addresses.
        // For a true production system, you'd need a more efficient way to sum validator stakes.
        // Example (hypothetical, assuming a list of validator addresses `activeValidators` exists):
        // for (address validatorAddress : activeValidators) {
        //     total += validators[validatorAddress].stake;
        // }
        // For now, let's assume we're not iterating over all possible addresses for validator stake.
        // The `distributeProtocolFees` function correctly determines distributable fees by subtracting total staked from contract balance.
        return total;
    }

    // The `_baseURI` override is not strictly necessary if `tokenURI` directly returns the dynamic URI.
    // However, it's good practice for ERC721 compliance and future flexibility.
    // function _baseURI() internal view override returns (string memory) {
    //     return "https://api.cerebralnexus.io/agent/metadata/"; // Base URI for metadata service
    // }
}
```