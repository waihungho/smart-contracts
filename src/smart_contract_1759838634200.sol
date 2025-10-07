Here's a Solidity smart contract named `AetherForge`, designed as a decentralized marketplace for AI/ML computational tasks. It incorporates advanced concepts like a reputation-backed, challenge-response proof-of-computation system, dynamic reward adjustments, and a simplified DAO for governance, all without directly duplicating existing open-source projects.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; // For initial owner, which can transition to a DAO
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Good practice for clarity with int256 arithmetic
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// ERC20 token interface for the platform's native token (FORGE)
interface IFORGEToken is IERC20 {
    // Assuming a simple ERC20, no mint/burn functions explicitly in this interface for simplicity.
    // If the token contract allows minting by AetherForge, it would be added here.
}

/**
 * @title AetherForge
 * @dev A decentralized marketplace for AI/ML computational tasks.
 *      Users can post tasks, compute nodes can bid and solve them.
 *      Features a reputation-backed challenge-response system for result verification,
 *      dynamic reward adjustment, and a basic DAO for parameter governance.
 */
contract AetherForge is Ownable, ReentrancyGuard {
    using SafeMath for uint256; // For uint256 operations
    // No SafeMath for int256 as its operations are typically handled directly by Solidity's default checked arithmetic
    // However, for int256, direct +/- could under/overflow. We'll manually check/clamp for reputation.

    // -------------------------------------------------------------------------------------------------------------
    // OUTLINE AND FUNCTION SUMMARY
    // -------------------------------------------------------------------------------------------------------------
    //
    // I. Core Platform Functions (Task Management)
    //    1.  createTask(TaskType _type, string memory _dataCID, uint256 _requiredStake, uint256 _bounty, uint256 _deadline):
    //        Allows users to create new AI/ML tasks (e.g., training, inference, data processing).
    //        Requires a bounty and a stake from the task creator.
    //    2.  submitTaskBid(uint256 _taskId, uint256 _bidAmount, string memory _proofOfCapabilityCID):
    //        Compute nodes can bid on open tasks, specifying their proposed cost and proof of capability.
    //        Requires a temporary stake from the bidding node.
    //    3.  selectWinningBid(uint256 _taskId, address _nodeAddress):
    //        Task creator selects a compute node's bid, initiating the task execution phase.
    //    4.  submitTaskResult(uint256 _taskId, string memory _resultCID):
    //        Selected compute node submits the cryptographic hash/CID of the task result.
    //    5.  challengeTaskResult(uint256 _taskId, address _solverAddress, string memory _reasonCID):
    //        Any participant (or Aether Core verifier) can challenge a submitted task result,
    //        requiring a challenge stake.
    //    6.  resolveChallenge(uint256 _challengeId, bool _isSolverCorrect):
    //        An Aether Core Verifier or DAO-approved entity resolves a challenge, impacting reputations and stakes.
    //    7.  finalizeTask(uint256 _taskId):
    //        Task creator marks a task as complete and correct, releasing funds to the solver and stakes.
    //    8.  cancelTask(uint256 _taskId):
    //        Task creator can cancel an unassigned task, recovering their stake and bounty.
    //
    // II. Compute Node Management
    //    9.  registerComputeNode(string memory _profileCID, uint256 _stakeAmount):
    //        Allows a participant to register as a compute node, staking FORGE tokens.
    //    10. updateNodeProfile(string memory _newProfileCID):
    //        Compute nodes can update their profile details (e.g., hardware specs, capabilities).
    //    11. deregisterComputeNode():
    //        Node can choose to deregister, entering a cooldown period before unstaking.
    //    12. unstakeNodeFunds():
    //        Allows a deregistered node to unstake their locked funds after the cooldown period.
    //    13. slashNodeStake(address _nodeAddress, uint256 _amount): (Internal)
    //        Function to slash a node's stake for misconduct (e.g., failed challenge).
    //    14. claimNodeRewards():
    //        Allows compute nodes to claim their accumulated FORGE rewards from successfully completed tasks.
    //
    // III. Reputation System
    //    15. updateReputationScore(address _nodeAddress, int256 _delta): (Internal)
    //        Function to adjust a compute node's reputation score based on performance.
    //    16. getNodeReputation(address _nodeAddress): (View)
    //        Retrieves the current reputation score of a compute node.
    //
    // IV. Token & Payment System
    //    17. depositFunds(uint256 _amount):
    //        Users deposit FORGE tokens into their platform balance for task bounties or stakes.
    //    18. withdrawFunds(uint256 _amount):
    //        Users withdraw available FORGE tokens from their platform balance.
    //    19. transferGovernanceTokens(address _to, uint256 _amount): (ERC20 Pass-through)
    //        Allows users to transfer FORGE tokens via the contract (if approved).
    //    20. approveGovernanceTokens(address _spender, uint256 _amount): (ERC20 Pass-through)
    //        Allows users to approve spending of FORGE tokens by another address via the contract.
    //
    // V. DAO Governance & Parameters (Simplified)
    //    21. proposeParameterChange(bytes32 _paramNameHash, uint256 _newValue, uint256 _executionDelay):
    //        Allows an authorized entity (initially owner, then DAO) to propose changes to system parameters.
    //    22. voteOnProposal(uint256 _proposalId, bool _for):
    //        Users can vote on active proposals. (Simplified: any address can vote, not token-weighted).
    //    23. executeProposal(uint256 _proposalId):
    //        Enacts a successfully voted-on proposal after its execution delay.
    //    24. setAetherCoreVerifier(address _verifier, bool _isVerifier):
    //        DAO-controlled function to add or remove trusted Aether Core Verifiers for challenges.
    //    25. getPlatformFee(): (View)
    //        Retrieves the current platform fee percentage.
    //
    // VI. Dynamic Pricing / Rewards
    //    26. calculateDynamicReward(uint256 _taskId, address _nodeAddress): (Internal/View)
    //        Function to calculate the final reward for a node, potentially adjusting
    //        the base bounty based on reputation, task complexity, and platform parameters.
    //
    // -------------------------------------------------------------------------------------------------------------

    IFORGEToken public immutable FORGE_TOKEN;

    // --- Configuration Parameters (initially set by owner, then by DAO) ---
    uint256 public minNodeStake;                 // Minimum stake required to register as a compute node
    uint256 public minTaskBounty;                // Minimum reward offered for a task
    uint256 public minTaskCreatorStake;          // Minimum stake required from a task creator
    uint256 public taskChallengeFee;             // Fee to challenge a task result
    uint256 public nodeDeregisterCooldown;       // Time (in seconds) before a node can unstake after deregistering
    uint256 public platformFeePercentage;        // Percentage fee taken by the platform (e.g., 200 = 2%, 10000 = 100%)
    uint256 public constant MAX_PLATFORM_FEE_PERCENTAGE = 1000; // Max 10%
    uint256 public constant REPUTATION_SCALE = 10000; // Base for reputation calculations
    int256 public constant INITIAL_REPUTATION = 10000; // Starting reputation for new nodes

    // --- Enums ---
    enum TaskType {
        Training,
        Inference,
        DataProcessing,
        Validation
    }

    enum TaskStatus {
        Open,            // Task created, awaiting bids
        AwaitingResult,  // Bid selected, node working
        ResultSubmitted, // Result submitted, awaiting finalization or challenge
        Challenged,      // Result challenged, awaiting resolution
        Completed,       // Task finalized, funds disbursed
        Cancelled        // Task cancelled
    }

    enum ChallengeStatus {
        Open,
        ResolvedCorrect,
        ResolvedIncorrect
    }

    // --- Structs ---
    struct Task {
        uint256 id;
        address creator;
        TaskType taskType;
        string dataCID;          // IPFS CID or other reference to input data/model
        uint256 creatorStake;    // Creator's stake, returned on completion
        uint256 bounty;          // Base reward for the solver
        uint256 deadline;        // Timestamp when task must be completed
        address assignedSolver;
        string resultCID;        // IPFS CID of the result
        TaskStatus status;
        uint256 creationTime;
    }

    struct Bid {
        uint256 taskId;
        address nodeAddress;
        uint256 bidAmount;            // Cost proposed by the node (should be <= task.bounty)
        string proofOfCapabilityCID;  // e.g., hash of system specs, specialized model
        uint256 nodeBidStake;         // Node's stake locked for this specific bid
        bool selected;
    }

    struct ComputeNode {
        bool registered;
        string profileCID;            // IPFS CID for node's detailed profile
        uint256 totalStaked;          // Total FORGE staked by this node (available for new bids)
        int256 reputationScore;       // Reputation score
        uint256 lastDeregisterRequest; // Timestamp of last deregister request, 0 if not deregistered
        uint256 accumulatedRewards;   // FORGE rewards awaiting claim
    }

    struct Challenge {
        uint256 id;
        uint256 taskId;
        address solver;
        address challenger;
        string reasonCID;             // IPFS CID for detailed challenge reason/proof
        uint256 challengeFeePaid;
        ChallengeStatus status;
        uint256 resolutionTime;
    }

    // Simplified DAO Proposal structure for parameter changes
    struct Proposal {
        uint256 id;
        bytes32 paramNameHash; // keccak256 of parameter name (e.g., "minNodeStake")
        uint256 newValue;
        uint256 creationTime;
        uint256 executionDelay; // Delay after voting ends before execution is possible
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // Tracks who has voted
        bool executed;
    }

    // --- Mappings & Counters ---
    uint256 public nextTaskId;
    uint256 public nextChallengeId;
    uint256 public nextProposalId;

    mapping(uint256 => Task) public tasks;
    mapping(uint256 => Bid[]) public taskBids;        // taskId => list of bids
    mapping(address => ComputeNode) public computeNodes;
    mapping(uint256 => Challenge) public challenges;
    mapping(address => uint256) public userBalances;  // User's deposited FORGE balance within the contract
    mapping(address => bool) public aetherCoreVerifiers; // Trusted verifiers, managed by DAO
    mapping(uint256 => Proposal) public proposals;

    // --- Events ---
    event TaskCreated(uint256 indexed taskId, address indexed creator, TaskType taskType, uint256 bounty, uint256 deadline);
    event BidSubmitted(uint256 indexed taskId, address indexed nodeAddress, uint256 bidAmount);
    event BidSelected(uint256 indexed taskId, address indexed creator, address indexed nodeAddress, uint256 bidAmount);
    event TaskResultSubmitted(uint256 indexed taskId, address indexed solver, string resultCID);
    event TaskFinalized(uint256 indexed taskId, address indexed creator, address indexed solver, uint256 finalReward);
    event TaskCancelled(uint256 indexed taskId, address indexed creator);
    event NodeRegistered(address indexed nodeAddress, string profileCID, uint256 stakedAmount);
    event NodeDeregistered(address indexed nodeAddress);
    event NodeUnstaked(address indexed nodeAddress, uint256 amount);
    event NodeReputationUpdated(address indexed nodeAddress, int256 newReputation);
    event ChallengeCreated(uint256 indexed challengeId, uint256 indexed taskId, address indexed challenger, address indexed solver);
    event ChallengeResolved(uint256 indexed challengeId, bool isSolverCorrect);
    event FundsDeposited(address indexed user, uint256 amount);
    event FundsWithdrawn(address indexed user, uint256 amount);
    event ProposalCreated(uint256 indexed proposalId, bytes32 paramNameHash, uint256 newValue);
    event Voted(uint256 indexed proposalId, address indexed voter, bool _for);
    event ProposalExecuted(uint256 indexed proposalId, bytes32 paramNameHash, uint256 newValue);
    event AetherCoreVerifierUpdated(address indexed verifier, bool isVerifier);
    event NodeStakeSlashed(address indexed nodeAddress, uint256 amount);

    // --- Constructor ---
    constructor(address _forgeTokenAddress) Ownable(msg.sender) {
        FORGE_TOKEN = IFORGEToken(_forgeTokenAddress);

        // Initial default parameters (can be changed by DAO later)
        minNodeStake = 1000 ether; // 1000 FORGE
        minTaskBounty = 10 ether;  // 10 FORGE
        minTaskCreatorStake = 5 ether; // 5 FORGE (creator's stake)
        taskChallengeFee = 20 ether; // 20 FORGE
        nodeDeregisterCooldown = 7 days; // 7 days cooldown
        platformFeePercentage = 200; // 2% (200 out of 10000)
    }

    // --- Modifiers ---
    modifier onlyRegisteredNode(address _node) {
        require(computeNodes[_node].registered, "AetherForge: Not a registered compute node");
        _;
    }

    modifier onlyAetherCoreVerifier() {
        require(aetherCoreVerifiers[msg.sender], "AetherForge: Only Aether Core verifiers can perform this action");
        _;
    }

    // --- I. Core Platform Functions (Task Management) ---

    /**
     * @notice Creates a new AI/ML task, requiring a bounty and a stake from the creator.
     * @param _type The type of task (e.g., Training, Inference).
     * @param _dataCID IPFS CID or other reference to the input data/model.
     * @param _requiredStake Creator's stake for the task, returned upon successful completion.
     * @param _bounty The reward for the compute node upon successful completion.
     * @param _deadline Timestamp by which the task must be completed.
     * @return The ID of the newly created task.
     */
    function createTask(
        TaskType _type,
        string memory _dataCID,
        uint256 _requiredStake,
        uint256 _bounty,
        uint256 _deadline
    ) external nonReentrant returns (uint256) {
        require(_bounty >= minTaskBounty, "AetherForge: Bounty below minimum");
        require(_requiredStake >= minTaskCreatorStake, "AetherForge: Creator stake below minimum");
        require(_deadline > block.timestamp, "AetherForge: Deadline must be in the future");
        require(userBalances[msg.sender] >= _requiredStake.add(_bounty), "AetherForge: Insufficient funds in balance");

        uint256 taskId = nextTaskId++;
        tasks[taskId] = Task({
            id: taskId,
            creator: msg.sender,
            taskType: _type,
            dataCID: _dataCID,
            creatorStake: _requiredStake,
            bounty: _bounty,
            deadline: _deadline,
            assignedSolver: address(0),
            resultCID: "",
            status: TaskStatus.Open,
            creationTime: block.timestamp
        });

        // Deduct funds from user balance and mark as locked for the task
        userBalances[msg.sender] = userBalances[msg.sender].sub(_requiredStake).sub(_bounty);

        emit TaskCreated(taskId, msg.sender, _type, _bounty, _deadline);
        return taskId;
    }

    /**
     * @notice Compute nodes can bid on open tasks. The node's stake for the bid is locked.
     * @param _taskId The ID of the task to bid on.
     * @param _bidAmount The proposed cost by the node to complete the task.
     * @param _proofOfCapabilityCID IPFS CID or reference to the node's proof of capability.
     */
    function submitTaskBid(
        uint256 _taskId,
        uint256 _bidAmount,
        string memory _proofOfCapabilityCID
    ) external onlyRegisteredNode(msg.sender) nonReentrant {
        Task storage task = tasks[_taskId];
        require(task.creator != address(0), "AetherForge: Task does not exist");
        require(task.status == TaskStatus.Open, "AetherForge: Task is not open for bids");
        require(task.creator != msg.sender, "AetherForge: Cannot bid on your own task");
        require(_bidAmount > 0 && _bidAmount <= task.bounty, "AetherForge: Bid must be positive and not exceed task bounty");
        
        // Node's stake for this bid (e.g., 10% of the bid amount, with a minimum)
        uint256 nodeBidStake = _bidAmount.div(10); // 10% of bid
        if (nodeBidStake < minTaskCreatorStake) nodeBidStake = minTaskCreatorStake; // Ensure minimum
        
        require(computeNodes[msg.sender].totalStaked >= nodeBidStake, "AetherForge: Insufficient available staked funds for bid");

        taskBids[_taskId].push(Bid({
            taskId: _taskId,
            nodeAddress: msg.sender,
            bidAmount: _bidAmount,
            proofOfCapabilityCID: _proofOfCapabilityCID,
            nodeBidStake: nodeBidStake,
            selected: false
        }));
        
        // Lock the node's stake for this specific bid
        computeNodes[msg.sender].totalStaked = computeNodes[msg.sender].totalStaked.sub(nodeBidStake);

        emit BidSubmitted(_taskId, msg.sender, _bidAmount);
    }

    /**
     * @notice Task creator selects a winning bid.
     * @param _taskId The ID of the task.
     * @param _nodeAddress The address of the compute node whose bid is selected.
     */
    function selectWinningBid(uint256 _taskId, address _nodeAddress) external nonReentrant {
        Task storage task = tasks[_taskId];
        require(task.creator == msg.sender, "AetherForge: Only task creator can select a bid");
        require(task.status == TaskStatus.Open, "AetherForge: Task is not open for bid selection");
        require(computeNodes[_nodeAddress].registered, "AetherForge: Selected address is not a registered node");

        uint256 selectedBidAmount = 0;
        uint256 selectedNodeBidStake = 0;
        bool found = false;

        for (uint i = 0; i < taskBids[_taskId].length; i++) {
            Bid storage bid = taskBids[_taskId][i];
            if (bid.nodeAddress == _nodeAddress) {
                require(!bid.selected, "AetherForge: Bid already selected");
                bid.selected = true; // Mark as selected
                selectedBidAmount = bid.bidAmount;
                selectedNodeBidStake = bid.nodeBidStake;
                found = true;
                break;
            }
        }
        require(found, "AetherForge: Bid not found for this node on this task");

        task.assignedSolver = _nodeAddress;
        task.status = TaskStatus.AwaitingResult;

        // Release stakes from other (unselected) bids back to nodes' available staked funds
        for (uint i = 0; i < taskBids[_taskId].length; i++) {
            Bid storage bid = taskBids[_taskId][i];
            if (!bid.selected) { // Only release for unselected bids
                computeNodes[bid.nodeAddress].totalStaked = computeNodes[bid.nodeAddress].totalStaked.add(bid.nodeBidStake);
            }
        }
        
        emit BidSelected(_taskId, msg.sender, _nodeAddress, selectedBidAmount);
    }

    /**
     * @notice Selected compute node submits the result hash/CID.
     * @param _taskId The ID of the task.
     * @param _resultCID IPFS CID or other reference to the task result.
     */
    function submitTaskResult(uint256 _taskId, string memory _resultCID) external nonReentrant onlyRegisteredNode(msg.sender) {
        Task storage task = tasks[_taskId];
        require(task.creator != address(0), "AetherForge: Task does not exist");
        require(task.assignedSolver == msg.sender, "AetherForge: Only the assigned solver can submit results");
        require(task.status == TaskStatus.AwaitingResult, "AetherForge: Task is not awaiting result submission");
        require(block.timestamp <= task.deadline, "AetherForge: Task deadline has passed");
        require(bytes(_resultCID).length > 0, "AetherForge: Result CID cannot be empty");

        task.resultCID = _resultCID;
        task.status = TaskStatus.ResultSubmitted;

        emit TaskResultSubmitted(_taskId, msg.sender, _resultCID);
    }

    /**
     * @notice Allows any participant or Aether Core verifier to challenge a submitted task result.
     *         Requires a challenge fee from the challenger.
     * @param _taskId The ID of the task.
     * @param _solverAddress The address of the solver who submitted the result.
     * @param _reasonCID IPFS CID or reference to the detailed reason and proof for the challenge.
     */
    function challengeTaskResult(
        uint256 _taskId,
        address _solverAddress,
        string memory _reasonCID
    ) external nonReentrant {
        Task storage task = tasks[_taskId];
        require(task.creator != address(0), "AetherForge: Task does not exist");
        require(task.assignedSolver == _solverAddress, "AetherForge: Solver address does not match assigned solver");
        require(task.status == TaskStatus.ResultSubmitted, "AetherForge: Task result is not in a challengeable state");
        require(userBalances[msg.sender] >= taskChallengeFee, "AetherForge: Insufficient funds for challenge fee");

        task.status = TaskStatus.Challenged;
        uint256 challengeId = nextChallengeId++;

        challenges[challengeId] = Challenge({
            id: challengeId,
            taskId: _taskId,
            solver: _solverAddress,
            challenger: msg.sender,
            reasonCID: _reasonCID,
            challengeFeePaid: taskChallengeFee,
            status: ChallengeStatus.Open,
            resolutionTime: 0
        });

        userBalances[msg.sender] = userBalances[msg.sender].sub(taskChallengeFee); // Lock challenge fee

        emit ChallengeCreated(challengeId, _taskId, msg.sender, _solverAddress);
    }

    /**
     * @notice Aether Core Verifiers or DAO-approved entities resolve challenges.
     *         This function adjusts stakes and reputations based on resolution.
     * @param _challengeId The ID of the challenge to resolve.
     * @param _isSolverCorrect True if the solver's result is deemed correct, false otherwise.
     */
    function resolveChallenge(uint256 _challengeId, bool _isSolverCorrect) external nonReentrant onlyAetherCoreVerifier {
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.id != 0, "AetherForge: Challenge does not exist");
        require(challenge.status == ChallengeStatus.Open, "AetherForge: Challenge is not open");

        Task storage task = tasks[challenge.taskId];
        require(task.status == TaskStatus.Challenged, "AetherForge: Task is not in challenged state");

        challenge.status = _isSolverCorrect ? ChallengeStatus.ResolvedCorrect : ChallengeStatus.ResolvedIncorrect;
        challenge.resolutionTime = block.timestamp;

        int256 reputationDelta;
        uint256 solverBidStake = 0;

        // Find the locked bid stake for the solver for this task
        for (uint i = 0; i < taskBids[task.id].length; i++) {
            Bid storage bid = taskBids[task.id][i];
            if (bid.nodeAddress == task.assignedSolver && bid.selected) {
                solverBidStake = bid.nodeBidStake;
                break;
            }
        }
        require(solverBidStake > 0, "AetherForge: Could not find solver's locked bid stake");

        if (_isSolverCorrect) {
            // Solver was correct: Challenger loses fee, solver gains reputation, task proceeds to finalization
            // Challenger's fee is burned (or transferred to DAO treasury, for simplicity burning now)
            FORGE_TOKEN.transfer(address(0), challenge.challengeFeePaid); 

            reputationDelta = 1000; // Positive reputation for solver
            task.status = TaskStatus.ResultSubmitted; // Back to submitted, awaiting finalization

            // Return solver's bid stake to their available staked funds
            computeNodes[challenge.solver].totalStaked = computeNodes[challenge.solver].totalStaked.add(solverBidStake);
        } else {
            // Solver was incorrect: Solver's stake is slashed, challenger gets fee back, solver loses reputation, task re-opens
            slashNodeStake(challenge.solver, solverBidStake);
            reputationDelta = -1000; // Negative reputation for solver
            task.status = TaskStatus.Open; // Task can be re-bid
            task.assignedSolver = address(0); // Unassign solver
            task.resultCID = ""; // Clear result

            // Return challenger's fee to their user balance
            userBalances[challenge.challenger] = userBalances[challenge.challenger].add(challenge.challengeFeePaid);
        }

        updateReputationScore(challenge.solver, reputationDelta);
        emit ChallengeResolved(_challengeId, _isSolverCorrect);
    }

    /**
     * @notice Task creator marks task as complete and correct, pays node, and claims their stake.
     * @param _taskId The ID of the task.
     */
    function finalizeTask(uint256 _taskId) external nonReentrant {
        Task storage task = tasks[_taskId];
        require(task.creator == msg.sender, "AetherForge: Only task creator can finalize task");
        require(task.status == TaskStatus.ResultSubmitted, "AetherForge: Task is not in a finalizable state");
        require(task.assignedSolver != address(0), "AetherForge: Task has no assigned solver");

        // Calculate actual reward, potentially adjusted dynamically
        uint256 finalReward = calculateDynamicReward(_taskId, task.assignedSolver);
        uint256 platformFee = finalReward.mul(platformFeePercentage).div(10000); // 10000 for 100%

        // Pay solver (add to their accumulated rewards)
        computeNodes[task.assignedSolver].accumulatedRewards = computeNodes[task.assignedSolver].accumulatedRewards.add(finalReward.sub(platformFee));

        // Transfer platform fee to contract (can be managed by DAO treasury later)
        FORGE_TOKEN.transfer(address(this), platformFee); 

        // Return creator's stake
        userBalances[task.creator] = userBalances[task.creator].add(task.creatorStake);

        // Release solver's bid stake to their available staked funds
        uint256 solverBidStake = 0;
        for (uint i = 0; i < taskBids[_taskId].length; i++) {
            Bid storage bid = taskBids[_taskId][i];
            if (bid.nodeAddress == task.assignedSolver && bid.selected) {
                solverBidStake = bid.nodeBidStake;
                break;
            }
        }
        computeNodes[task.assignedSolver].totalStaked = computeNodes[task.assignedSolver].totalStaked.add(solverBidStake);

        // Update solver reputation for successful completion
        updateReputationScore(task.assignedSolver, 500); 

        task.status = TaskStatus.Completed;
        emit TaskFinalized(_taskId, msg.sender, task.assignedSolver, finalReward.sub(platformFee));
    }

    /**
     * @notice Task creator cancels an unassigned task.
     * @param _taskId The ID of the task to cancel.
     */
    function cancelTask(uint256 _taskId) external nonReentrant {
        Task storage task = tasks[_taskId];
        require(task.creator == msg.sender, "AetherForge: Only task creator can cancel task");
        require(task.status == TaskStatus.Open, "AetherForge: Only open tasks can be cancelled");

        // Return creator's stake and bounty to their user balance
        userBalances[msg.sender] = userBalances[msg.sender].add(task.creatorStake).add(task.bounty);

        task.status = TaskStatus.Cancelled;
        emit TaskCancelled(_taskId, msg.sender);
    }

    // --- II. Compute Node Management ---

    /**
     * @notice Registers a new compute node, requiring an initial stake.
     * @param _profileCID IPFS CID or other reference to the node's profile details.
     * @param _stakeAmount The amount of FORGE tokens to stake.
     */
    function registerComputeNode(string memory _profileCID, uint256 _stakeAmount) external nonReentrant {
        require(!computeNodes[msg.sender].registered, "AetherForge: Node already registered");
        require(_stakeAmount >= minNodeStake, "AetherForge: Stake amount below minimum");
        require(userBalances[msg.sender] >= _stakeAmount, "AetherForge: Insufficient funds in balance to stake");

        computeNodes[msg.sender] = ComputeNode({
            registered: true,
            profileCID: _profileCID,
            totalStaked: _stakeAmount, // This is the 'available' staked amount
            reputationScore: INITIAL_REPUTATION,
            lastDeregisterRequest: 0,
            accumulatedRewards: 0
        });

        userBalances[msg.sender] = userBalances[msg.sender].sub(_stakeAmount);
        emit NodeRegistered(msg.sender, _profileCID, _stakeAmount);
    }

    /**
     * @notice Allows a registered node to update its profile.
     * @param _newProfileCID New IPFS CID for the node's detailed profile.
     */
    function updateNodeProfile(string memory _newProfileCID) external onlyRegisteredNode(msg.sender) {
        computeNodes[msg.sender].profileCID = _newProfileCID;
    }

    /**
     * @notice Allows a node to request deregistration. Stake is locked during a cooldown period.
     *         Note: A more robust system would ensure no active tasks or pending bids before allowing deregistration.
     */
    function deregisterComputeNode() external onlyRegisteredNode(msg.sender) nonReentrant {
        // For simplicity, we allow deregistration immediately, but funds are locked by cooldown
        // A production system might require no active tasks or open bids.
        computeNodes[msg.sender].registered = false;
        computeNodes[msg.sender].lastDeregisterRequest = block.timestamp;
        emit NodeDeregistered(msg.sender);
    }
    
    /**
     * @notice Allows a deregistered node to unstake their funds after the cooldown period.
     */
    function unstakeNodeFunds() external nonReentrant {
        ComputeNode storage node = computeNodes[msg.sender];
        require(!node.registered, "AetherForge: Node is still registered");
        require(node.lastDeregisterRequest > 0, "AetherForge: No deregistration request found");
        require(block.timestamp >= node.lastDeregisterRequest.add(nodeDeregisterCooldown), "AetherForge: Deregister cooldown period not over");
        require(node.totalStaked > 0, "AetherForge: No staked funds to unstake");

        uint256 amountToUnstake = node.totalStaked;
        node.totalStaked = 0; // Clear staked amount
        node.lastDeregisterRequest = 0; // Reset deregistration state
        userBalances[msg.sender] = userBalances[msg.sender].add(amountToUnstake);
        emit NodeUnstaked(msg.sender, amountToUnstake);
    }

    /**
     * @notice Internal function to slash a node's stake for misconduct.
     *         Slashed funds are currently burned.
     * @param _nodeAddress The address of the node to slash.
     * @param _amount The amount of FORGE to slash.
     */
    function slashNodeStake(address _nodeAddress, uint256 _amount) internal {
        ComputeNode storage node = computeNodes[_nodeAddress];
        // Node must be registered or recently deregistered (stake still held)
        require(node.registered || (node.lastDeregisterRequest > 0 && node.totalStaked > 0), "AetherForge: Node not recognized or no stake to slash");
        require(node.totalStaked >= _amount, "AetherForge: Slash amount exceeds available staked funds");

        node.totalStaked = node.totalStaked.sub(_amount);
        // Slashed funds are currently burned (sent to address(0))
        FORGE_TOKEN.transfer(address(0), _amount); 
        emit NodeStakeSlashed(_nodeAddress, _amount);
    }

    /**
     * @notice Allows compute nodes to claim their accumulated FORGE rewards.
     */
    function claimNodeRewards() external nonReentrant onlyRegisteredNode(msg.sender) {
        ComputeNode storage node = computeNodes[msg.sender];
        require(node.accumulatedRewards > 0, "AetherForge: No accumulated rewards to claim");

        uint256 rewards = node.accumulatedRewards;
        node.accumulatedRewards = 0;
        userBalances[msg.sender] = userBalances[msg.sender].add(rewards);
        emit FundsWithdrawn(msg.sender, rewards); // Re-using FundsWithdrawn for clarity, it's a withdrawal from internal balance.
    }

    // --- III. Reputation System ---

    /**
     * @notice Internal function to adjust a compute node's reputation score.
     *         Reputation is clamped to prevent extreme values.
     * @param _nodeAddress The address of the node.
     * @param _delta The amount to add or subtract from the reputation score.
     */
    function updateReputationScore(address _nodeAddress, int256 _delta) internal {
        ComputeNode storage node = computeNodes[_nodeAddress];
        // Only update reputation for active or recently active nodes
        if (!node.registered && node.lastDeregisterRequest == 0) return; 

        int256 newScore = node.reputationScore + _delta;
        // Clamp reputation to a reasonable range (e.g., 0 to 2 * INITIAL_REPUTATION)
        if (newScore < 0) newScore = 0;
        if (newScore > int256(INITIAL_REPUTATION).mul(2)) newScore = int256(INITIAL_REPUTATION).mul(2);
        
        node.reputationScore = newScore;
        emit NodeReputationUpdated(_nodeAddress, newScore);
    }

    /**
     * @notice Retrieves the current reputation score of a compute node.
     * @param _nodeAddress The address of the node.
     * @return The reputation score.
     */
    function getNodeReputation(address _nodeAddress) public view returns (int256) {
        return computeNodes[_nodeAddress].reputationScore;
    }

    // --- IV. Token & Payment System ---

    /**
     * @notice Users deposit FORGE tokens into their platform balance.
     *         Tokens are transferred from msg.sender to the contract.
     * @param _amount The amount of FORGE tokens to deposit.
     */
    function depositFunds(uint256 _amount) external nonReentrant {
        require(_amount > 0, "AetherForge: Deposit amount must be greater than zero");
        FORGE_TOKEN.transferFrom(msg.sender, address(this), _amount);
        userBalances[msg.sender] = userBalances[msg.sender].add(_amount);
        emit FundsDeposited(msg.sender, _amount);
    }

    /**
     * @notice Users withdraw available FORGE tokens from their platform balance.
     *         Tokens are transferred from the contract back to msg.sender.
     * @param _amount The amount of FORGE tokens to withdraw.
     */
    function withdrawFunds(uint256 _amount) external nonReentrant {
        require(_amount > 0, "AetherForge: Withdrawal amount must be greater than zero");
        require(userBalances[msg.sender] >= _amount, "AetherForge: Insufficient withdrawable balance");

        userBalances[msg.sender] = userBalances[msg.sender].sub(_amount);
        FORGE_TOKEN.transfer(msg.sender, _amount);
        emit FundsWithdrawn(msg.sender, _amount);
    }

    /**
     * @notice Standard ERC20 transfer function, allowing users to transfer their FORGE tokens
     *         that they have approved this contract to spend on their behalf.
     * @param _to The recipient address.
     * @param _amount The amount to transfer.
     * @return True if transfer was successful.
     */
    function transferGovernanceTokens(address _to, uint256 _amount) external returns (bool) {
        // This assumes the user has given the AetherForge contract approval to spend their FORGE tokens.
        // It's a pass-through for convenience.
        return FORGE_TOKEN.transferFrom(msg.sender, _to, _amount);
    }

    /**
     * @notice Standard ERC20 approve function, allowing users to approve another address (spender)
     *         to spend a specified amount of their FORGE tokens.
     * @param _spender The spender address.
     * @param _amount The amount to approve.
     * @return True if approval was successful.
     */
    function approveGovernanceTokens(address _spender, uint256 _amount) external returns (bool) {
        // This directly approves spending from msg.sender's FORGE balance.
        return FORGE_TOKEN.approve(_spender, _amount);
    }

    // --- V. DAO Governance & Parameters (Simplified) ---
    // This is a very basic DAO for parameter changes. A full-fledged DAO would likely be a separate contract
    // with token-weighted voting, more complex proposal types, and a treasury.

    uint256 public constant PROPOSAL_VOTE_THRESHOLD_PERCENTAGE = 5100; // 51% (out of 10000)
    uint256 public constant PROPOSAL_VOTING_PERIOD = 3 days;

    /**
     * @notice Allows an authorized entity (initially owner, then DAO) to propose changes to system parameters.
     * @param _paramNameHash A hash identifying the parameter to change (e.g., keccak256("minNodeStake")).
     * @param _newValue The new value for the parameter.
     * @param _executionDelay The delay (in seconds) after successful vote before the proposal can be executed.
     * @return The ID of the newly created proposal.
     */
    function proposeParameterChange(
        bytes32 _paramNameHash,
        uint256 _newValue,
        uint256 _executionDelay
    ) external onlyOwner returns (uint256) { // Simplified: only owner can propose for now, later transition to DAO
        uint256 proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            id: proposalId,
            paramNameHash: _paramNameHash,
            newValue: _newValue,
            creationTime: block.timestamp,
            executionDelay: _executionDelay,
            votesFor: 0,
            votesAgainst: 0,
            hasVoted: new mapping(address => bool), 
            executed: false
        });
        emit ProposalCreated(proposalId, _paramNameHash, _newValue);
        return proposalId;
    }

    /**
     * @notice Users can vote on active proposals. (Simplified: any address can vote, not token-weighted).
     * @param _proposalId The ID of the proposal to vote on.
     * @param _for True for a 'yes' vote, false for a 'no' vote.
     */
    function voteOnProposal(uint256 _proposalId, bool _for) external {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "AetherForge: Proposal does not exist");
        require(!proposal.executed, "AetherForge: Proposal already executed");
        require(block.timestamp < proposal.creationTime.add(PROPOSAL_VOTING_PERIOD), "AetherForge: Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "AetherForge: Already voted on this proposal");

        proposal.hasVoted[msg.sender] = true;
        if (_for) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        emit Voted(_proposalId, msg.sender, _for);
    }

    /**
     * @notice Enacts a successfully voted-on proposal after its execution delay.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external onlyOwner { // Simplified: only owner executes for now
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "AetherForge: Proposal does not exist");
        require(!proposal.executed, "AetherForge: Proposal already executed");
        require(block.timestamp >= proposal.creationTime.add(PROPOSAL_VOTING_PERIOD), "AetherForge: Voting period not ended");
        require(block.timestamp >= proposal.creationTime.add(PROPOSAL_VOTING_PERIOD).add(proposal.executionDelay), "AetherForge: Execution delay not over");

        uint256 totalVotes = proposal.votesFor.add(proposal.votesAgainst);
        require(totalVotes > 0, "AetherForge: No votes cast");
        require(proposal.votesFor.mul(10000).div(totalVotes) >= PROPOSAL_VOTE_THRESHOLD_PERCENTAGE, "AetherForge: Proposal did not pass");

        proposal.executed = true;

        // Apply the parameter change based on paramNameHash
        if (proposal.paramNameHash == keccak256("minNodeStake")) {
            minNodeStake = proposal.newValue;
        } else if (proposal.paramNameHash == keccak256("minTaskBounty")) {
            minTaskBounty = proposal.newValue;
        } else if (proposal.paramNameHash == keccak256("minTaskCreatorStake")) {
            minTaskCreatorStake = proposal.newValue;
        } else if (proposal.paramNameHash == keccak256("taskChallengeFee")) {
            taskChallengeFee = proposal.newValue;
        } else if (proposal.paramNameHash == keccak256("nodeDeregisterCooldown")) {
            nodeDeregisterCooldown = proposal.newValue;
        } else if (proposal.paramNameHash == keccak256("platformFeePercentage")) {
            require(proposal.newValue <= MAX_PLATFORM_FEE_PERCENTAGE, "AetherForge: Platform fee exceeds max allowed");
            platformFeePercentage = proposal.newValue;
        } else {
            revert("AetherForge: Unknown parameter for execution");
        }

        emit ProposalExecuted(_proposalId, proposal.paramNameHash, proposal.newValue);
    }

    /**
     * @notice Allows the DAO (or initial owner) to manage the list of trusted Aether Core Verifiers.
     * @param _verifier The address of the verifier.
     * @param _isVerifier True to add, false to remove.
     */
    function setAetherCoreVerifier(address _verifier, bool _isVerifier) external onlyOwner { // Or only DAO-controlled later
        aetherCoreVerifiers[_verifier] = _isVerifier;
        emit AetherCoreVerifierUpdated(_verifier, _isVerifier);
    }

    /**
     * @notice Retrieves the current platform fee percentage.
     * @return The platform fee percentage (e.g., 200 for 2%).
     */
    function getPlatformFee() public view returns (uint256) {
        return platformFeePercentage;
    }

    // --- VI. Dynamic Pricing / Rewards ---

    /**
     * @notice Internal function to calculate the final reward for a node, dynamically adjusted.
     *         This is a placeholder for a more complex dynamic model.
     * @param _taskId The ID of the task.
     * @param _nodeAddress The address of the compute node.
     * @return The dynamically calculated reward.
     */
    function calculateDynamicReward(uint256 _taskId, address _nodeAddress) internal view returns (uint256) {
        Task storage task = tasks[_taskId];
        ComputeNode storage node = computeNodes[_nodeAddress];

        uint256 baseBounty = task.bounty;
        int256 reputation = node.reputationScore;

        uint256 adjustedBounty = baseBounty;

        // Simple dynamic adjustment: Higher reputation means a slight bonus, lower a slight penalty.
        // This formula can be extended with external oracle data (e.g., compute market prices),
        // task complexity multipliers, network congestion, etc., for a more advanced system.
        if (reputation > INITIAL_REPUTATION) {
            // Bonus for good reputation, e.g., up to 5% bonus for very high reputation
            // Max reputation is 2 * INITIAL_REPUTATION. So max (INITIAL_REPUTATION * 100) / INITIAL_REPUTATION = 100
            // Then scale 100 to 5% (500/10000)
            uint256 bonusFactor = (uint256(reputation).sub(uint256(INITIAL_REPUTATION))).mul(500).div(uint256(INITIAL_REPUTATION)); 
            if (bonusFactor > 500) bonusFactor = 500; // Cap bonus at 5% (500/10000)
            adjustedBounty = adjustedBounty.add(adjustedBounty.mul(bonusFactor).div(10000));
        } else if (reputation < INITIAL_REPUTATION) {
            // Penalty for low reputation, e.g., up to 5% penalty
            uint256 penaltyFactor = (uint256(INITIAL_REPUTATION).sub(uint256(reputation))).mul(500).div(uint256(INITIAL_REPUTATION));
            if (penaltyFactor > 500) penaltyFactor = 500; // Cap penalty at 5%
            adjustedBounty = adjustedBounty.sub(adjustedBounty.mul(penaltyFactor).div(10000));
        }

        return adjustedBounty;
    }

    // Fallback and Receive functions to prevent accidental ETH transfers
    receive() external payable {
        revert("AetherForge: ETH not accepted, please use FORGE token");
    }

    fallback() external payable {
        revert("AetherForge: ETH not accepted, please use FORGE token");
    }
}
```