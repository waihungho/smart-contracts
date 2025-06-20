Okay, here is a complex, creative, and feature-rich smart contract concept for a Decentralized AI Compute Marketplace. It combines elements of decentralized work, reputation systems, NFT-based resources, and a dispute resolution mechanism.

**Core Concept:**
A marketplace where users (Requesters) can submit AI/ML computation tasks and providers (Nodes) can offer their computing power to fulfill these tasks, earning rewards. The contract manages the state of tasks, nodes, payments, and a reputation system, relying on off-chain components (compute, matching, result verification) while providing on-chain guarantees for payment, staking, and node ownership (via NFTs).

**Outline:**

1.  **Pragma & Imports:** Specify Solidity version and import necessary interfaces (ERC721, Ownable, Pausable).
2.  **Interfaces:** Define interfaces for external contracts (e.g., a custom ERC721 for Compute Node NFTs).
3.  **Errors:** Custom errors for clarity and gas efficiency.
4.  **Events:** Define events for significant state changes.
5.  **Structs:** Define data structures for `Task`, `ComputeNode`, and `Dispute`.
6.  **Enums:** Define enums for task and node statuses.
7.  **State Variables:** Declare mappings, counters, addresses, and configuration variables.
8.  **Modifiers:** Custom modifiers for access control and contract state.
9.  **Constructor:** Initialize contract owner, potentially link to NFT contract.
10. **Core Task Management Functions:** Functions for submitting, canceling, assigning, completing, and verifying tasks.
11. **Dispute Resolution Functions:** Functions for disputing results and resolving disputes.
12. **Payment & Withdrawal Functions:** Functions for handling payments and user withdrawals.
13. **Compute Node (NFT) Management Functions:** Functions for registering, updating, and deregistering compute nodes represented by NFTs.
14. **Reputation System Functions:** View functions for reputation scores. (Updates handled internally by task/dispute functions).
15. **Parameter & Fee Management Functions:** Owner functions to configure marketplace parameters and withdraw fees.
16. **Access Control & Admin Functions:** Functions for managing roles (e.g., verifiers, matchers) and pausing the contract.
17. **View Functions:** Read-only functions to query contract state.
18. **Internal Helper Functions:** Private functions for internal logic (e.g., handling payouts, reputation updates, stake slashing).

**Function Summary (At least 20 functions):**

1.  `submitTaskRequest`: Create a new task request.
2.  `cancelTaskRequest`: Cancel a task request if not yet assigned.
3.  `assignTaskToProvider`: (Role: Matcher) Assign a pending task to an available compute node/provider.
4.  `submitTaskResult`: Provider submits the result of an assigned task.
5.  `verifyTaskResult`: (Role: Verifier) Approve a submitted result (for non-disputed tasks).
6.  `disputeTaskResult`: Requester disputes a submitted result.
7.  `resolveDispute`: (Role: Verifier/Oracle) Resolve a disputed task based on off-chain evidence.
8.  `registerComputeNode`: Provider stakes funds and registers a compute node (mints an NFT).
9.  `updateNodeStatus`: Provider updates the status of their registered node.
10. `updateNodeCapabilities`: Provider updates the description hash of their node's capabilities.
11. `deregisterComputeNode`: Provider unstakes funds and deregisters a node (burns NFT).
12. `withdrawFunds`: Users (requesters/providers) withdraw earned funds or returned collateral/stake.
13. `slashStake`: (Role: Verifier/Oracle) Slash a provider's stake due to verifiable fraud/failure in a dispute.
14. `setTaskFeePercentage`: (Owner) Set the marketplace fee for completed tasks.
15. `setMinProviderStake`: (Owner) Set the minimum stake required for a provider/node.
16. `setDisputePeriod`: (Owner) Set the duration allowed for disputing results.
17. `withdrawPlatformFees`: (Owner) Withdraw accumulated platform fees.
18. `addAllowedVerifier`: (Owner) Add an address authorized to verify results and resolve disputes.
19. `removeAllowedVerifier`: (Owner) Remove an authorized verifier address.
20. `addAllowedMatcher`: (Owner) Add an address authorized to assign tasks to providers.
21. `removeAllowedMatcher`: (Owner) Remove an authorized matcher address.
22. `pauseContract`: (Owner) Pause core contract functionality in emergencies.
23. `unpauseContract`: (Owner) Resume core contract functionality.
24. `getTaskDetails`: (View) Get details of a specific task.
25. `getNodeDetails`: (View) Get details of a specific compute node.
26. `getProviderReputation`: (View) Get the reputation score for a provider.
27. `listPendingTasks`: (View) Get a list of tasks awaiting assignment.
28. `listProviderNodes`: (View) Get a list of node IDs owned by a provider.
29. `getAllowedVerifiers`: (View) Get the list of allowed verifier addresses.
30. `getAllowedMatchers`: (View) Get the list of allowed matcher addresses.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// --- Outline ---
// 1. Pragma & Imports
// 2. Interfaces (for external contracts like Node NFT)
// 3. Errors
// 4. Events
// 5. Structs (Task, ComputeNode, Dispute)
// 6. Enums (TaskStatus, NodeStatus)
// 7. State Variables (counters, mappings, configs, roles)
// 8. Modifiers (access control, pause)
// 9. Constructor
// 10. Core Task Management Functions
// 11. Dispute Resolution Functions
// 12. Payment & Withdrawal Functions
// 13. Compute Node (NFT) Management Functions
// 14. Reputation System Functions (mostly view)
// 15. Parameter & Fee Management Functions
// 16. Access Control & Admin Functions (Roles, Pause)
// 17. View Functions
// 18. Internal Helper Functions

// --- Function Summary (>= 20 functions) ---
// 1.  submitTaskRequest(uint256 rewardAmount, bytes32 descriptionHash, string memory dataCID) - Create a task.
// 2.  cancelTaskRequest(uint256 taskId) - Cancel task before assignment.
// 3.  assignTaskToProvider(uint256 taskId, uint256 nodeId) - Matcher assigns task to node.
// 4.  submitTaskResult(uint256 taskId, string memory resultCID) - Provider submits result.
// 5.  verifyTaskResult(uint256 taskId, bool success) - Verifier verifies non-disputed result.
// 6.  disputeTaskResult(uint256 taskId, string memory evidenceCID) - Requester disputes result.
// 7.  resolveDispute(uint256 taskId, bool requesterWins, string memory resolutionDetailsCID) - Verifier resolves dispute.
// 8.  registerComputeNode(bytes32 capabilitiesHash) - Provider stakes and registers node (mints NFT).
// 9.  updateNodeStatus(uint256 nodeId, NodeStatus newStatus) - Provider updates node availability.
// 10. updateNodeCapabilities(uint256 nodeId, bytes32 capabilitiesHash) - Provider updates node specs hash.
// 11. deregisterComputeNode(uint256 nodeId) - Provider unstakes and deregisters node (burns NFT).
// 12. withdrawFunds() - Withdraw available balance.
// 13. slashStake(uint256 nodeId, uint256 amount) - Verifier/Oracle slashes provider stake.
// 14. setTaskFeePercentage(uint16 percentage) - Owner sets platform fee.
// 15. setMinProviderStake(uint256 amount) - Owner sets min stake per node.
// 16. setDisputePeriod(uint64 duration) - Owner sets dispute timeout.
// 17. withdrawPlatformFees() - Owner withdraws collected fees.
// 18. addAllowedVerifier(address verifier) - Owner adds verifier role.
// 19. removeAllowedVerifier(address verifier) - Owner removes verifier role.
// 20. addAllowedMatcher(address matcher) - Owner adds matcher role.
// 21. removeAllowedMatcher(address matcher) - Owner removes matcher role.
// 22. pauseContract() - Owner pauses.
// 23. unpauseContract() - Owner unpauses.
// 24. getTaskDetails(uint256 taskId) - View task details.
// 25. getNodeDetails(uint256 nodeId) - View node details.
// 26. getProviderReputation(address provider) - View provider reputation.
// 27. listPendingTasks() - View pending tasks (simplified list of IDs).
// 28. listProviderNodes(address provider) - View node IDs owned by provider.
// 29. getAllowedVerifiers() - View verifier list.
// 30. getAllowedMatchers() - View matcher list.
// 31. getTaskCount() - View total tasks.
// 32. getNodeCount() - View total nodes.
// 33. getMinProviderStake() - View min stake config.
// 34. getTaskFeePercentage() - View fee config.
// 35. getDisputePeriod() - View dispute period config.

// Assuming a separate ERC721 contract exists for Compute Nodes
interface IComputeNodeNFT is IERC721 {
    function mint(address to, uint256 tokenId) external;
    function burn(uint256 tokenId) external;
    // Add other relevant NFT functions if needed, e.g., for metadata
}

contract DecentralizedAIComputeMarketplace is Ownable, Pausable, ReentrancyGuard, IERC721Receiver {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet; // For listing task IDs

    // --- Errors ---
    error TaskNotFound(uint256 taskId);
    error TaskNotInStatus(uint256 taskId, TaskStatus requiredStatus);
    error NodeNotFound(uint256 nodeId);
    error NodeNotInStatus(uint256 nodeId, NodeStatus requiredStatus);
    error NodeNotOwnedBy(uint256 nodeId, address owner);
    error TaskNotAssignedToNode(uint256 taskId, uint256 nodeId);
    error InsufficientPayment();
    error InsufficientStake();
    error AlreadyStaked(uint256 nodeId);
    error NotEnoughBalance();
    error DisputePeriodExpired(uint256 taskId);
    error NotAllowedVerifier();
    error NotAllowedMatcher();
    error NoFundsToWithdraw();
    error InvalidPercentage(uint16 percentage);

    // --- Events ---
    event TaskRequested(uint256 indexed taskId, address indexed requester, uint256 rewardAmount, bytes32 descriptionHash, string dataCID);
    event TaskCancelled(uint256 indexed taskId);
    event TaskAssigned(uint256 indexed taskId, uint256 indexed nodeId, address indexed provider);
    event TaskResultSubmitted(uint256 indexed taskId, uint256 indexed nodeId, string resultCID);
    event TaskVerified(uint256 indexed taskId, bool indexed success); // success relates to the outcome vs expectation
    event TaskDisputed(uint256 indexed taskId, address indexed disputer, string evidenceCID);
    event DisputeResolved(uint256 indexed taskId, bool indexed requesterWins, string resolutionDetailsCID);
    event NodeRegistered(uint256 indexed nodeId, address indexed provider, bytes32 capabilitiesHash, uint256 stakeAmount);
    event NodeStatusUpdated(uint256 indexed nodeId, NodeStatus newStatus);
    event NodeDeregistered(uint256 indexed nodeId, address indexed provider, uint256 remainingStake);
    event FundsWithdrawn(address indexed user, uint256 amount);
    event ProviderStakeSlashed(uint256 indexed nodeId, address indexed provider, uint256 amount);
    event TaskFeePercentageUpdated(uint16 newPercentage);
    event MinProviderStakeUpdated(uint256 newAmount);
    event DisputePeriodUpdated(uint64 newDuration);
    event PlatformFeesWithdrawn(uint256 amount);
    event AllowedVerifierAdded(address indexed verifier);
    event AllowedVerifierRemoved(address indexed verifier);
    event AllowedMatcherAdded(address indexed matcher);
    event AllowedMatcherRemoved(address indexed matcher);

    // --- Structs ---
    enum TaskStatus {
        Pending,         // Waiting for assignment
        Assigned,        // Assigned to a node, computing
        ResultSubmitted, // Result submitted, waiting for verification/dispute
        Disputed,        // Result is disputed
        Verified,        // Result verified, payment distributed
        Cancelled,       // Cancelled by requester
        Failed           // Task failed (e.g., provider failed, dispute outcome)
    }

    enum NodeStatus {
        Available,
        Busy,
        Offline,
        Maintenance
    }

    struct Task {
        uint256 id;
        address requester;
        uint256 rewardAmount;
        bytes32 descriptionHash; // Hash of off-chain task description (e.g., model, parameters)
        string dataCID;          // IPFS CID or similar for input data
        uint256 collateralAmount; // Requester's staked amount (reward + potential dispute collateral)
        TaskStatus status;
        uint256 assignedNodeId; // 0 if not assigned
        string resultCID;        // IPFS CID for output data
        uint64 submissionTime;
        uint64 resultSubmissionTime; // Time when result was submitted
        uint64 disputeDeadline;
        address currentProvider; // The provider assigned to this task
    }

    struct ComputeNode {
        uint256 id;       // Matches NFT token ID
        address owner;    // The provider address
        NodeStatus status;
        bytes32 capabilitiesHash; // Hash of off-chain description (CPU, GPU, RAM, software env)
        uint256 stakedAmount;
        uint64 registeredAt;
        bool isRegistered; // To easily check existence
    }

    // Although not a struct, we track per-address balances for withdrawals
    mapping(address => uint256) private userBalances;
    uint256 private totalPlatformFees;

    // --- State Variables ---
    uint256 private nextTaskId = 1;
    uint256 private nextNodeId = 1; // NodeId maps directly to NFT tokenId

    mapping(uint256 => Task) public tasks;
    mapping(uint256 => ComputeNode) public computeNodes;
    mapping(address => EnumerableSet.UintSet) private providerNodeIds; // Keep track of nodes per provider
    mapping(address => int256) public providerReputation; // Simple integer score for reputation

    // Configuration Parameters
    uint16 public taskFeePercentage = 500; // 5.00% (stored as basis points)
    uint256 public minProviderStake;      // Minimum stake required per registered node
    uint64 public disputePeriod = 24 hours; // Default dispute period duration

    // Access Control Roles
    EnumerableSet.AddressSet private allowedVerifiers; // Addresses allowed to verify results/resolve disputes
    EnumerableSet.AddressSet private allowedMatchers;  // Addresses allowed to assign tasks

    // Reference to the Compute Node NFT contract
    IComputeNodeNFT public immutable computeNodeNFT;

    // --- Constructor ---
    constructor(address _computeNodeNFTAddress, uint256 _minProviderStake) Ownable(msg.sender) Pausable(false) {
        computeNodeNFT = IComputeNodeNFT(_computeNodeNFTAddress);
        minProviderStake = _minProviderStake;
        // Add owner as a default verifier and matcher for testing/initial setup
        allowedVerifiers.add(msg.sender);
        allowedMatchers.add(msg.sender);
    }

    // --- Modifiers ---
    modifier onlyAllowedVerifier() {
        if (!allowedVerifiers.contains(msg.sender)) {
            revert NotAllowedVerifier();
        }
        _;
    }

     modifier onlyAllowedMatcher() {
        if (!allowedMatchers.contains(msg.sender)) {
            revert NotAllowedMatcher();
        }
        _;
    }

    modifier onlyTaskRequester(uint256 taskId) {
        if (tasks[taskId].requester != msg.sender) {
            revert("Not Task Requester"); // Generic or add custom error
        }
        _;
    }

    modifier onlyTaskProvider(uint256 taskId) {
        if (tasks[taskId].currentProvider != msg.sender) {
            revert("Not Task Provider"); // Generic or add custom error
        }
        _;
    }

    modifier onlyNodeOwner(uint256 nodeId) {
         if (!computeNodes[nodeId].isRegistered || computeNodes[nodeId].owner != msg.sender) {
            revert NodeNotOwnedBy(nodeId, msg.sender);
        }
        _;
    }

    // --- Core Task Management Functions ---

    /**
     * @notice Submits a new AI computation task request.
     * @param rewardAmount The amount of native currency offered for the task.
     * @param descriptionHash A hash of the task's detailed description (stored off-chain).
     * @param dataCID The CID (e.g., IPFS) pointing to the input data.
     * @dev The sender must send `msg.value` equal to `rewardAmount` plus potential collateral.
     *      Requester collateral can be used for disputes. Let's set it to rewardAmount for simplicity.
     */
    function submitTaskRequest(
        uint256 rewardAmount,
        bytes32 descriptionHash,
        string memory dataCID
    ) external payable whenNotPaused nonReentrant {
        uint256 requiredPayment = rewardAmount + rewardAmount; // Reward + Collateral
        if (msg.value < requiredPayment) {
            revert InsufficientPayment();
        }

        uint256 taskId = nextTaskId++;
        tasks[taskId] = Task({
            id: taskId,
            requester: msg.sender,
            rewardAmount: rewardAmount,
            descriptionHash: descriptionHash,
            dataCID: dataCID,
            collateralAmount: msg.value, // Store the full sent amount as collateral
            status: TaskStatus.Pending,
            assignedNodeId: 0,
            resultCID: "",
            submissionTime: uint64(block.timestamp),
            resultSubmissionTime: 0,
            disputeDeadline: 0,
            currentProvider: address(0)
        });

        // Keep track of pending tasks - simple set for listing, actual matching is off-chain
        pendingTaskIds.add(taskId);

        emit TaskRequested(taskId, msg.sender, rewardAmount, descriptionHash, dataCID);
    }

    /**
     * @notice Cancels a task request if it hasn't been assigned yet.
     * @param taskId The ID of the task to cancel.
     */
    function cancelTaskRequest(uint256 taskId)
        external
        whenNotPaused
        onlyTaskRequester(taskId)
        nonReentrant
    {
        Task storage task = tasks[taskId];
        if (task.status != TaskStatus.Pending) {
            revert TaskNotInStatus(taskId, TaskStatus.Pending);
        }

        task.status = TaskStatus.Cancelled;
        // Return the full collateral back to the requester's balance
        userBalances[task.requester] += task.collateralAmount;
        pendingTaskIds.remove(taskId); // Remove from pending list

        emit TaskCancelled(taskId);
    }

    /**
     * @notice Assigns a pending task to an available compute node.
     * @dev This function is expected to be called by an authorized 'Matcher' role,
     *      likely an off-chain service that performs task-to-node matching.
     * @param taskId The ID of the task to assign.
     * @param nodeId The ID of the compute node to assign the task to.
     */
    function assignTaskToProvider(uint256 taskId, uint256 nodeId)
        external
        whenNotPaused
        onlyAllowedMatcher
        nonReentrant
    {
        Task storage task = tasks[taskId];
        ComputeNode storage node = computeNodes[nodeId];

        if (task.status != TaskStatus.Pending) {
            revert TaskNotInStatus(taskId, TaskStatus.Pending);
        }
         if (!node.isRegistered) {
            revert NodeNotFound(nodeId);
        }
        if (node.status != NodeStatus.Available) {
            revert NodeNotInStatus(nodeId, NodeStatus.Available);
        }

        task.status = TaskStatus.Assigned;
        task.assignedNodeId = nodeId;
        task.currentProvider = node.owner;

        node.status = NodeStatus.Busy; // Mark node as busy

        pendingTaskIds.remove(taskId); // Remove from pending list

        emit TaskAssigned(taskId, nodeId, node.owner);
    }

    /**
     * @notice Submits the result of an assigned task.
     * @param taskId The ID of the task.
     * @param resultCID The CID (e.g., IPFS) pointing to the output data.
     */
    function submitTaskResult(uint256 taskId, string memory resultCID)
        external
        whenNotPaused
        onlyTaskProvider(taskId)
        nonReentrant
    {
        Task storage task = tasks[taskId];
         if (task.status != TaskStatus.Assigned) {
            revert TaskNotInStatus(taskId, TaskStatus.Assigned);
        }
         if (task.assignedNodeId == 0) {
             // Should not happen if status is Assigned, but safety check
             revert "Task not correctly assigned";
         }
        ComputeNode storage node = computeNodes[task.assignedNodeId];

        task.resultCID = resultCID;
        task.status = TaskStatus.ResultSubmitted;
        task.resultSubmissionTime = uint64(block.timestamp);
        task.disputeDeadline = uint64(block.timestamp) + disputePeriod;

        node.status = NodeStatus.Available; // Node is now available for new tasks

        emit TaskResultSubmitted(taskId, task.assignedNodeId, resultCID);
    }

    /**
     * @notice Verifies the result of a completed task that was NOT disputed.
     * @dev This function is expected to be called by an authorized 'Verifier' role,
     *      likely an off-chain service that validates task results.
     * @param taskId The ID of the task to verify.
     * @param success True if the result is valid and meets requirements, false otherwise (e.g., computation error).
     */
    function verifyTaskResult(uint256 taskId, bool success)
        external
        whenNotPaused
        onlyAllowedVerifier
        nonReentrant
    {
        Task storage task = tasks[taskId];
        if (task.status != TaskStatus.ResultSubmitted) {
            revert TaskNotInStatus(taskId, TaskStatus.ResultSubmitted);
        }
        // Ensure dispute period has NOT expired if dispute was possible
        if (block.timestamp > task.disputeDeadline && !success) {
             // If dispute period passed and result is considered failed by verifier,
             // requester lost the opportunity to dispute. Task fails, requester collateral locked,
             // provider stake returned (unless other slashing mechanism applies).
             // Simpler approach for this contract: If dispute period passes, task becomes Verified automatically (success=true implied).
             // Let's enforce verification *before* dispute period ends OR if dispute period ended, success MUST be true.
             revert("Cannot verify as failed after dispute period"); // Or handle auto-verify success
        }


        task.status = TaskStatus.Verified; // Task is now completed/verified regardless of outcome

        // Handle payment/collateral based on success
        uint256 platformFee = (task.rewardAmount * taskFeePercentage) / 10000;
        uint256 providerReward = task.rewardAmount - platformFee;

        if (success) {
            // Provider gets reward, Requester gets collateral back
            userBalances[task.currentProvider] += providerReward;
            userBalances[task.requester] += task.collateralAmount - task.rewardAmount; // Return requester's collateral minus reward cost
             _updateReputation(task.currentProvider, 1); // Increase provider reputation
        } else {
            // Provider failed, gets nothing. Requester gets full collateral back.
             userBalances[task.requester] += task.collateralAmount; // Return full collateral
             // Provider stake *could* be slashed here depending on severity.
             // For simplicity, let's just reduce reputation for failure.
             _updateReputation(task.currentProvider, -1); // Decrease provider reputation
        }

        totalPlatformFees += platformFee;

        emit TaskVerified(taskId, success);
    }

    /**
     * @notice Allows the requester to dispute a submitted task result within the dispute period.
     * @param taskId The ID of the task to dispute.
     * @param evidenceCID The CID (e.g., IPFS) pointing to the evidence for the dispute.
     */
    function disputeTaskResult(uint256 taskId, string memory evidenceCID)
        external
        whenNotPaused
        onlyTaskRequester(taskId)
        nonReentrant
    {
        Task storage task = tasks[taskId];
        if (task.status != TaskStatus.ResultSubmitted) {
            revert TaskNotInStatus(taskId, TaskStatus.ResultSubmitted);
        }
        if (block.timestamp > task.disputeDeadline) {
            revert DisputePeriodExpired(taskId);
        }

        task.status = TaskStatus.Disputed;
        // In a real system, dispute details (evidenceCID, etc.) would be stored.
        // For this example, we just change status and store evidenceCID implicitly in Task struct (resultCID is overwritten).
        // Let's add a separate dispute struct in a more advanced version. For now, evidenceCID just noted via event.
        emit TaskDisputed(taskId, msg.sender, evidenceCID);
    }

     /**
     * @notice Resolves a disputed task. Distributes funds based on the outcome.
     * @dev This function is expected to be called by an authorized 'Verifier' role,
     *      likely an off-chain oracle or dispute resolution body.
     * @param taskId The ID of the task under dispute.
     * @param requesterWins True if the dispute is resolved in favor of the requester, false if provider wins.
     * @param resolutionDetailsCID The CID (e.g., IPFS) pointing to the details of the dispute resolution decision.
     */
    function resolveDispute(uint256 taskId, bool requesterWins, string memory resolutionDetailsCID)
        external
        whenNotPaused
        onlyAllowedVerifier
        nonReentrant
    {
        Task storage task = tasks[taskId];
        if (task.status != TaskStatus.Disputed) {
            revert TaskNotInStatus(taskId, TaskStatus.Disputed);
        }

        task.status = TaskStatus.Verified; // Dispute resolved, task is finalized

        uint256 platformFee = (task.rewardAmount * taskFeePercentage) / 10000;
        uint256 providerPotentialReward = task.rewardAmount - platformFee; // Max the provider could have gotten
        uint256 requesterCollateral = task.collateralAmount; // Full amount sent by requester

        if (requesterWins) {
            // Requester wins: Gets collateral back. Provider loses potential reward.
            userBalances[task.requester] += requesterCollateral;
            _updateReputation(task.currentProvider, -2); // Significant reputation loss for failure/fraud
            // Provider's stake on the node might be slashed in this scenario by a separate call or logic.
        } else {
            // Provider wins: Gets reward. Requester loses reward amount from collateral, gets rest back.
            userBalances[task.currentProvider] += providerPotentialReward;
            userBalances[task.requester] += requesterCollateral - task.rewardAmount; // Return collateral minus reward cost
             _updateReputation(task.currentProvider, 2); // Reputation boost for successfully defending dispute
        }

        totalPlatformFees += platformFee;

        emit DisputeResolved(taskId, requesterWins, resolutionDetailsCID);
    }


    // --- Payment & Withdrawal Functions ---

    /**
     * @notice Allows users to withdraw their accumulated balances.
     */
    function withdrawFunds() external nonReentrant {
        uint256 amount = userBalances[msg.sender];
        if (amount == 0) {
            revert NoFundsToWithdraw();
        }

        userBalances[msg.sender] = 0;

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Withdrawal failed"); // Should ideally handle failure better or use pull payments

        emit FundsWithdrawn(msg.sender, amount);
    }

    // --- Compute Node (NFT) Management Functions ---

    /**
     * @notice Registers a new compute node by staking funds and minting an NFT.
     * @param capabilitiesHash Hash of the off-chain description of node capabilities.
     * @dev Mints a unique ERC721 token managed by this contract's linked NFT contract.
     *      The node ID is the token ID.
     */
    function registerComputeNode(bytes32 capabilitiesHash) external payable whenNotPaused nonReentrant {
        if (msg.value < minProviderStake) {
            revert InsufficientStake();
        }

        uint256 nodeId = nextNodeId++;

        computeNodes[nodeId] = ComputeNode({
            id: nodeId,
            owner: msg.sender,
            status: NodeStatus.Available,
            capabilitiesHash: capabilitiesHash,
            stakedAmount: msg.value,
            registeredAt: uint64(block.timestamp),
            isRegistered: true
        });

        providerNodeIds[msg.sender].add(nodeId);

        // Mint the corresponding NFT token and transfer ownership to this contract or user?
        // Let's mint it to the user (provider), giving them direct ownership, but
        // the node status & stake are managed by THIS marketplace contract.
        // The marketplace contract needs approval or operator status to manage these NFTs.
        // Simpler: Mint to the MARKETPLACE contract, and the `computeNodes` mapping
        // grants "logical" control to the provider while stake/status is managed here.
        // Provider proves node ownership by owning the NFT managed by the marketplace.
        // Let's mint to the marketplace contract address.
        computeNodeNFT.mint(address(this), nodeId);


        emit NodeRegistered(nodeId, msg.sender, capabilitiesHash, msg.value);
    }

    /**
     * @notice Updates the status of a registered compute node.
     * @param nodeId The ID of the node to update.
     * @param newStatus The new status for the node.
     */
    function updateNodeStatus(uint256 nodeId, NodeStatus newStatus)
        external
        whenNotPaused
        onlyNodeOwner(nodeId)
    {
         ComputeNode storage node = computeNodes[nodeId];
         // Prevent setting busy manually, this is done by assignTaskToProvider
         if (newStatus == NodeStatus.Busy) {
             revert("Cannot set status to Busy directly");
         }
         // Prevent deregistering if busy - handled in deregisterComputeNode

        node.status = newStatus;
        emit NodeStatusUpdated(nodeId, newStatus);
    }

    /**
     * @notice Updates the capabilities hash of a registered compute node.
     * @param nodeId The ID of the node to update.
     * @param capabilitiesHash The new hash of capabilities.
     */
     function updateNodeCapabilities(uint256 nodeId, bytes32 capabilitiesHash)
        external
        whenNotPaused
        onlyNodeOwner(nodeId)
    {
        computeNodes[nodeId].capabilitiesHash = capabilitiesHash;
        // No specific event for this, maybe general NodeUpdated? Or add one if needed.
    }

    /**
     * @notice Deregisters a compute node and returns the staked funds.
     * @dev Requires the node not to be currently busy with a task. Burns the associated NFT.
     * @param nodeId The ID of the node to deregister.
     */
    function deregisterComputeNode(uint256 nodeId)
        external
        whenNotPaused
        onlyNodeOwner(nodeId)
        nonReentrant
    {
        ComputeNode storage node = computeNodes[nodeId];

        if (node.status == NodeStatus.Busy) {
            revert NodeNotInStatus(nodeId, NodeStatus.Available); // Needs to be available
        }

        uint256 stakeToReturn = node.stakedAmount;
        userBalances[msg.sender] += stakeToReturn; // Return stake to provider's balance

        // Mark node as no longer registered
        node.isRegistered = false;
        // Clear node data (optional, but good practice)
        delete computeNodes[nodeId];

        providerNodeIds[msg.sender].remove(nodeId);

        // Burn the corresponding NFT token
        computeNodeNFT.burn(nodeId);

        emit NodeDeregistered(nodeId, msg.sender, stakeToReturn);
    }

    /**
     * @notice Allows an authorized verifier/oracle to slash a provider's stake.
     * @dev Intended for penalizing providers for fraudulent behavior detected off-chain
     *      and confirmed by the oracle/verifier role, typically during dispute resolution.
     * @param nodeId The ID of the compute node whose owner's stake is to be slashed.
     * @param amount The amount of stake to slash.
     */
    function slashStake(uint256 nodeId, uint256 amount)
        external
        whenNotPaused
        onlyAllowedVerifier // Assumes verifier is the entity deciding on slashing
        nonReentrant
    {
        ComputeNode storage node = computeNodes[nodeId];
        if (!node.isRegistered) {
             // Cannot slash if not registered, or use a different mechanism for past offenses
             revert NodeNotFound(nodeId);
        }
        if (amount == 0) {
            revert("Slash amount must be greater than 0");
        }
        if (amount > node.stakedAmount) {
            amount = node.stakedAmount; // Cannot slash more than is staked
        }

        node.stakedAmount -= amount;
        totalPlatformFees += amount; // Slashed stake goes to platform fees

        emit ProviderStakeSlashed(nodeId, node.owner, amount);
    }


    // --- Reputation System Functions ---
    // Reputation is updated internally by task verification and dispute resolution
    // _updateReputation is the internal helper

    /**
     * @notice Gets the current reputation score for a provider address.
     * @param provider The address of the provider.
     * @return The reputation score.
     */
    function getProviderReputation(address provider) external view returns (int256) {
        return providerReputation[provider];
    }


    // --- Parameter & Fee Management Functions ---

    /**
     * @notice Sets the percentage of the task reward taken as platform fee.
     * @dev Stored in basis points (e.g., 500 for 5.00%). Max 10000 (100%).
     * @param percentage The new fee percentage in basis points.
     */
    function setTaskFeePercentage(uint16 percentage) external onlyOwner {
        if (percentage > 10000) {
            revert InvalidPercentage(percentage);
        }
        taskFeePercentage = percentage;
        emit TaskFeePercentageUpdated(percentage);
    }

    /**
     * @notice Sets the minimum stake required for a provider to register a compute node.
     * @param amount The new minimum stake amount in native currency units.
     */
    function setMinProviderStake(uint256 amount) external onlyOwner {
        minProviderStake = amount;
        emit MinProviderStakeUpdated(amount);
    }

    /**
     * @notice Sets the duration of the dispute period after result submission.
     * @param duration The new dispute period duration in seconds.
     */
    function setDisputePeriod(uint64 duration) external onlyOwner {
        disputePeriod = duration;
        emit DisputePeriodUpdated(duration);
    }

    /**
     * @notice Allows the owner to withdraw accumulated platform fees.
     */
    function withdrawPlatformFees() external onlyOwner nonReentrant {
        uint256 amount = totalPlatformFees;
        if (amount == 0) {
            revert NoFundsToWithdraw(); // Reusing error, maybe custom fee error
        }

        totalPlatformFees = 0;

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Fee withdrawal failed"); // Should ideally handle failure better

        emit PlatformFeesWithdrawn(amount);
    }

    // --- Access Control & Admin Functions ---

    /**
     * @notice Adds an address to the list of authorized verifiers.
     * @dev Verifiers can call verifyTaskResult and resolveDispute.
     * @param verifier The address to add.
     */
    function addAllowedVerifier(address verifier) external onlyOwner {
        if (allowedVerifiers.add(verifier)) {
            emit AllowedVerifierAdded(verifier);
        }
    }

    /**
     * @notice Removes an address from the list of authorized verifiers.
     * @param verifier The address to remove.
     */
    function removeAllowedVerifier(address verifier) external onlyOwner {
         if (allowedVerifiers.remove(verifier)) {
            emit AllowedVerifierRemoved(verifier);
        }
    }

     /**
     * @notice Adds an address to the list of authorized matchers.
     * @dev Matchers can call assignTaskToProvider.
     * @param matcher The address to add.
     */
    function addAllowedMatcher(address matcher) external onlyOwner {
        if (allowedMatchers.add(matcher)) {
            emit AllowedMatcherAdded(matcher);
        }
    }

    /**
     * @notice Removes an address from the list of authorized matchers.
     * @param matcher The address to remove.
     */
    function removeAllowedMatcher(address matcher) external onlyOwner {
         if (allowedMatchers.remove(matcher)) {
            emit AllowedMatcherRemoved(matcher);
        }
    }

    /**
     * @notice Pauses the contract, preventing most state-changing operations.
     */
    function pauseContract() external onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @notice Unpauses the contract, allowing operations to resume.
     */
    function unpauseContract() external onlyOwner whenPaused {
        _unpause();
    }


    // --- View Functions ---

    /**
     * @notice Gets details of a specific task.
     * @param taskId The ID of the task.
     * @return Task struct details.
     */
    function getTaskDetails(uint256 taskId) external view returns (Task memory) {
        // Revert if task doesn't exist based on default struct values (requester address 0)
        if (tasks[taskId].requester == address(0)) {
            revert TaskNotFound(taskId);
        }
        return tasks[taskId];
    }

    /**
     * @notice Gets details of a specific compute node.
     * @param nodeId The ID of the node.
     * @return ComputeNode struct details.
     */
    function getNodeDetails(uint256 nodeId) external view returns (ComputeNode memory) {
         if (!computeNodes[nodeId].isRegistered) {
            revert NodeNotFound(nodeId);
        }
        return computeNodes[nodeId];
    }

    // Using EnumerableSet for pending tasks
    EnumerableSet.UintSet private pendingTaskIds;

    /**
     * @notice Gets a list of task IDs that are currently pending assignment.
     * @return An array of pending task IDs.
     */
    function listPendingTasks() external view returns (uint256[] memory) {
        return pendingTaskIds.values();
    }

     /**
     * @notice Gets a list of compute node IDs owned by a specific provider.
     * @param provider The address of the provider.
     * @return An array of node IDs.
     */
    function listProviderNodes(address provider) external view returns (uint256[] memory) {
        return providerNodeIds[provider].values();
    }

    /**
     * @notice Gets the list of addresses allowed to verify results and resolve disputes.
     * @return An array of allowed verifier addresses.
     */
    function getAllowedVerifiers() external view returns (address[] memory) {
        return allowedVerifiers.values();
    }

     /**
     * @notice Gets the list of addresses allowed to assign tasks to providers.
     * @return An array of allowed matcher addresses.
     */
    function getAllowedMatchers() external view returns (address[] memory) {
        return allowedMatchers.values();
    }

     /**
     * @notice Gets the total number of tasks ever submitted.
     * @return The total task count.
     */
    function getTaskCount() external view returns (uint256) {
        return nextTaskId - 1; // nextTaskId is the next available ID, so count is ID - 1
    }

    /**
     * @notice Gets the total number of compute nodes ever registered.
     * @return The total node count.
     */
    function getNodeCount() external view returns (uint256) {
        return nextNodeId - 1; // nextNodeId is the next available ID, so count is ID - 1
    }

     /**
     * @notice Gets the currently configured minimum provider stake amount.
     * @return The minimum stake amount.
     */
    function getMinProviderStake() external view returns (uint256) {
        return minProviderStake;
    }

    /**
     * @notice Gets the currently configured task fee percentage.
     * @return The task fee percentage in basis points.
     */
    function getTaskFeePercentage() external view returns (uint16) {
        return taskFeePercentage;
    }

     /**
     * @notice Gets the currently configured dispute period duration.
     * @return The dispute period duration in seconds.
     */
    function getDisputePeriod() external view returns (uint64) {
        return disputePeriod;
    }


    // --- Internal Helper Functions ---

    /**
     * @notice Internal function to update a provider's reputation score.
     * @param provider The address of the provider.
     * @param change The amount to change the reputation score by (positive or negative).
     */
    function _updateReputation(address provider, int256 change) internal {
        // Simple additive reputation. More complex systems could use decay,
        // weighted changes based on stake/task size, etc.
        providerReputation[provider] += change;
        // Optional: Emit ReputationUpdated event
    }

    // ERC721Receiver interface function
    // This is required if the marketplace contract receives NFTs (e.g., when they are minted to it)
    // It tells the NFT contract that this contract knows how to handle NFTs.
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external override returns (bytes4) {
        // We only expect to receive NFTs from the computeNodeNFT contract itself during minting.
        // We could add checks here if needed (e.g., require msg.sender == address(computeNodeNFT))
        return IERC721Receiver.onERC721Received.selector;
    }

    // Receive function to allow receiving native currency
    receive() external payable {}
    // Fallback function (optional, but good practice)
    fallback() external payable {}
}
```

**Explanation of Advanced Concepts & Creativity:**

1.  **Decentralized Compute Marketplace:** The core concept itself is modern, leveraging blockchain to coordinate off-chain computation providers and requesters.
2.  **NFT-based Resources:** Compute nodes are represented by ERC721 NFTs (`ComputeNodeNFT`). This provides a standardized, transferrable, and potentially tradeable way for providers to represent their stake and right to participate in the network. The NFT ownership and the node's operational state (managed in the marketplace contract) are linked.
3.  **Staking Mechanisms:** Both requesters (via task collateral) and providers (via node stake) lock funds. This aligns incentives, ensures task validity, and provides a pool for rewards, dispute payouts, or slashing.
4.  **Reputation System:** A simple on-chain integer reputation score tracks provider performance (`providerReputation`). It's updated based on successful task completion and dispute outcomes, helping requesters choose reliable providers (though matching might be off-chain).
5.  **Role-Based Access Control (Custom):** Instead of just `onlyOwner`, it introduces `onlyAllowedVerifier` and `onlyAllowedMatcher` roles. This allows off-chain oracles, matching engines, or decentralized autonomous organizations (DAOs) to interact with the contract within specific permissions, decentralizing operational aspects beyond just the owner.
6.  **Dispute Resolution Framework:** Includes mechanisms for disputing results and resolving them via an authorized 'Verifier' role. This is crucial for trust in decentralized work, handling cases where computation is incorrect or fraudulent. Slashed stake adds a financial penalty layer.
7.  **State Management of Off-chain Work:** The contract doesn't *perform* computation or *verify* results itself (as that's impossible/impractical on EVM). Instead, it manages the *state* of these processes (Pending -> Assigned -> ResultSubmitted -> Verified/Disputed), using CIDs (IPFS or similar) to reference off-chain data, and relying on trusted (or eventually decentralized) off-chain verifiers/oracles to report outcomes via specific functions.
8.  **Pull Payments:** Users `withdrawFunds()` rather than receiving pushes, mitigating reentrancy risks.
9.  **Error Handling:** Uses custom errors (`revert TaskNotFound()`, etc.) which are more gas-efficient and provide clearer debugging than string messages in modern Solidity.
10. **Pausable:** Standard security pattern for emergency stops.
11. **EnumerableSet:** Used for managing lists of pending tasks and provider nodes efficiently on-chain.
12. **Modular Design:** Assumes external contracts for NFTs, allowing for flexibility and upgrades of specific components (like the NFT contract) if needed.

This contract provides a robust framework for a decentralized AI compute marketplace, showcasing how blockchain can orchestrate complex off-chain processes with on-chain financial guarantees and state tracking.