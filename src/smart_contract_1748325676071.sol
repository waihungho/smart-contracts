Okay, let's design a smart contract for a **Decentralized AI Compute Marketplace**. This concept is trendy due to the rise of AI and the need for distributed compute resources, and it incorporates advanced concepts like staking, reputation, task management lifecycle, and dispute resolution on-chain.

We will avoid duplicating standard open-source patterns directly by creating a specific workflow for task creation, bidding, execution proof, and payout/dispute, integrated with a simple reputation system.

Here is the outline and function summary, followed by the Solidity source code.

---

## Smart Contract: DecentralizedAIComputeMarketplace

**Concept:** A marketplace where users can request compute tasks (specifically framed for AI/ML, but general compute), and registered providers can bid on and execute these tasks. The contract manages the task lifecycle, handles payment, implements staking for commitment and dispute resolution, and maintains a simple provider reputation system.

**Core Features:**
*   Task Creation with Staking
*   Provider Registration and Availability
*   Task Bidding by Providers
*   Bid Acceptance by Requestor
*   Proof Submission by Provider
*   Task Completion Confirmation by Requestor
*   Automated Payouts and Stake Management
*   Simplified On-chain Dispute Resolution (Arbitrator-based)
*   Provider Reputation Tracking
*   Task Expiration Handling

**Data Structures:**
*   `Provider`: Represents a registered compute provider with an address, reputation score, and active status.
*   `Bid`: Represents a provider's bid on a specific task, including price, estimated time, and stake.
*   `Task`: Represents a compute task request with details like requestor, provider, status, price, deadlines, stakes, and linked data/result URIs.

**Enums:**
*   `TaskStatus`: Tracks the current state of a task (Open, Bidding, Assigned, ProofSubmitted, Completed, Disputed, Cancelled, Expired).

**Outline & Function Summary:**

**I. State Variables & Configuration**
*   `arbitrator`: Address responsible for resolving disputes.
*   `erc20Token`: Address of the ERC-20 token used for payments and staking.
*   `minRequestorStake`: Minimum stake required from a requestor to create a task.
*   `minProviderStake`: Minimum stake required from a provider to bid on a task.
*   `disputeFee`: Fee required to raise a dispute.
*   `slashingPercentage`: Percentage of provider stake to slash on failure/dispute loss.
*   `providers`: Mapping from address to `Provider` struct.
*   `isRegisteredProvider`: Mapping to quickly check if an address is a provider.
*   `tasks`: Mapping from task ID to `Task` struct.
*   `taskBids`: Mapping from task ID to an array of `Bid` structs (or provider address to bid?). *Let's use a mapping from task ID to provider address to bid for easier unique bids per provider per task.*
*   `openTaskIds`: An array of IDs for tasks in the `Open` or `Bidding` state (for easier querying). *Or better, just iterate tasks or use events.* Let's stick to iterating or events for simplicity and gas, direct array for open tasks can be gas-expensive to maintain. Query functions will iterate or rely on external indexing.
*   `nextTaskId`: Counter for unique task IDs.

**II. Provider Management Functions**
1.  `registerProvider()`: Allows an address to register as a compute provider.
2.  `setProviderActiveStatus(bool _isActive)`: Allows a registered provider to set their active/available status.
3.  `getProviderDetails(address _provider)`: View function to get details of a registered provider.
4.  `getProviderReputation(address _provider)`: View function to get the reputation score of a provider.
5.  `isProviderRegistered(address _provider)`: View function to check if an address is a registered provider.

**III. Task Lifecycle Functions**
6.  `createComputeTask(uint256 _maxPrice, uint64 _duration, string memory _dataURI)`: Creates a new compute task, requires requestor stake.
7.  `bidOnTask(uint256 _taskId, uint256 _price, uint64 _eta)`: Allows a registered, active provider to bid on an open task, requires provider stake.
8.  `acceptBid(uint256 _taskId, address _provider)`: Allows the task requestor to accept a bid from a specific provider.
9.  `submitResultProof(uint256 _taskId, string memory _resultURI, string memory _proofDetails)`: Allows the assigned provider to submit proof of task completion.
10. `confirmTaskCompletion(uint256 _taskId)`: Allows the task requestor to confirm the result is satisfactory, triggering payment to the provider and stake release.
11. `cancelTask(uint256 _taskId)`: Allows the requestor to cancel an open task before a bid is accepted.
12. `raiseDispute(uint256 _taskId)`: Allows either the requestor or the assigned provider to raise a dispute, requires dispute fee stake.
13. `arbitrateDispute(uint256 _taskId, address _winner)`: Allows the arbitrator to resolve a dispute, distributing stakes and potentially slashing.
14. `handleTaskExpiration(uint256 _taskId)`: Allows anyone to trigger expiration handling for a task that passed its deadline in certain states (e.g., Assigned but no proof submitted).

**IV. Query Functions (View)**
15. `getTaskDetails(uint256 _taskId)`: Get all details of a specific task.
16. `getTaskBids(uint256 _taskId)`: Get all bids placed on a specific task.
17. `getOpenTasks(uint256 _startIndex, uint256 _count)`: Get a paginated list of task IDs that are currently open for bidding. (Requires iterating or external indexing; will simulate with range check). *Correction: Iterating through all tasks is too gas-intensive for a public view function if task count grows large. Let's focus on specific task lookups and rely on external indexing for broad searches like "open tasks". We can provide `getTaskStatus` as a helper.*
18. `getTaskStatus(uint256 _taskId)`: Get the current status of a task.
19. `getTasksByRequestor(address _requestor)`: Get a list of task IDs created by a specific requestor. *Again, iteration is costly. Let's add mappings `requestor -> taskIds[]` and `provider -> taskIds[]` for efficient lookup, though writing to arrays in mappings adds gas cost.* Let's add helper arrays for this.
20. `getTasksByProvider(address _provider)`: Get a list of task IDs assigned to or bid on by a specific provider. (Need separate arrays for assigned vs. bid?) Let's track assigned tasks per provider.
21. `getArbitrator()`: Get the current arbitrator address.
22. `getMinimumStakes()`: Get the current minimum requestor and provider stakes.
23. `getDisputeFee()`: Get the current dispute fee.
24. `getSlashingPercentage()`: Get the current slashing percentage.

**V. Admin Functions**
25. `setArbitrator(address _newArbitrator)`: Owner can change the arbitrator address.
26. `setMinimumStakes(uint256 _minRequestorStake, uint256 _minProviderStake)`: Owner can set minimum staking amounts.
27. `setDisputeFee(uint256 _disputeFee)`: Owner can set the dispute fee.
28. `setSlashingPercentage(uint256 _slashingPercentage)`: Owner can set the slashing percentage.

*(Total Functions: 28, exceeding the requirement of 20)*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title Decentralized AI Compute Marketplace
/// @author Your Name/Alias (Inspired by decentralized compute concepts)
/// @notice This contract facilitates a marketplace for AI/ML compute tasks.
/// Users request tasks, providers bid and execute, payment and disputes are handled on-chain.

contract DecentralizedAIComputeMarketplace is Ownable, ReentrancyGuard {

    // --- Data Structures ---

    struct Provider {
        address providerAddress;
        int256 reputationScore; // Simple integer score
        bool isActive;          // Available for new tasks
    }

    struct Bid {
        address provider;
        uint256 price;    // Price in ERC20 tokens
        uint64 eta;       // Estimated time to completion in seconds
        uint256 stake;    // Provider stake for this bid
    }

    enum TaskStatus {
        Open,             // Task created, waiting for bids
        Bidding,          // Bids have been placed, requestor can accept
        Assigned,         // Bid accepted, provider working on task
        ProofSubmitted,   // Provider submitted result/proof
        Completed,        // Requestor confirmed completion, payment pending/sent
        Disputed,         // Dispute raised, waiting for arbitration
        Cancelled,        // Task cancelled by requestor
        Expired           // Task deadline passed in Assigned/ProofSubmitted state
    }

    struct Task {
        uint256 id;
        address requestor;
        address assignedProvider;
        uint256 maxPrice;       // Maximum price requestor is willing to pay
        uint256 acceptedPrice;  // Actual accepted bid price
        uint64 duration;        // Max duration for task execution (from acceptance) in seconds
        uint64 deadline;        // Timestamp when the task expires (from acceptance)
        string dataURI;         // URI pointing to input data/task specification
        string resultURI;       // URI pointing to the result
        string proofDetails;    // Details/hash for verification proof
        TaskStatus status;
        uint256 requestorStake; // Stake locked by requestor
        uint256 providerStake;  // Stake locked by assigned provider
        uint256 disputeFeeStake; // Stake locked for dispute
        mapping(address => Bid) bids; // Bids submitted by providers for this task
        address[] bidderAddresses; // Array of addresses that have placed bids
    }

    // --- State Variables ---

    address public arbitrator;
    IERC20 public immutable erc20Token;

    uint256 public minRequestorStake;
    uint256 public minProviderStake;
    uint256 public disputeFee;
    uint256 public slashingPercentage; // e.g., 100 = 100% slash, 10 = 10% slash

    mapping(address => Provider) public providers;
    mapping(address => bool) public isRegisteredProvider; // Helper mapping

    mapping(uint256 => Task) public tasks;
    uint256 private nextTaskId;

    // Mappings for faster lookup (may become large)
    mapping(address => uint256[]) public requestorTaskIds;
    mapping(address => uint256[]) public providerAssignedTaskIds;

    // --- Events ---

    event ProviderRegistered(address indexed provider);
    event ProviderStatusChanged(address indexed provider, bool isActive);
    event TaskCreated(uint256 indexed taskId, address indexed requestor, uint256 maxPrice, uint64 duration, string dataURI);
    event BidPlaced(uint256 indexed taskId, address indexed provider, uint256 price, uint64 eta);
    event BidAccepted(uint256 indexed taskId, address indexed requestor, address indexed provider, uint256 acceptedPrice);
    event ResultProofSubmitted(uint256 indexed taskId, address indexed provider, string resultURI);
    event TaskCompleted(uint256 indexed taskId, address indexed requestor, address indexed provider, uint256 finalPrice);
    event TaskCancelled(uint256 indexed taskId, address indexed requestor);
    event TaskExpired(uint256 indexed taskId);
    event DisputeRaised(uint256 indexed taskId, address indexed party);
    event DisputeArbitrated(uint256 indexed taskId, address indexed winner, address indexed loser);
    event StakeWithdrawn(address indexed account, uint256 amount);
    event StakeLocked(address indexed account, uint256 amount, uint256 indexed taskId);
    event StakeReleased(address indexed account, uint256 amount, uint256 indexed taskId);
    event StakeSlashed(address indexed account, uint256 amount, uint256 indexed taskId);
    event FundsTransferred(address indexed from, address indexed to, uint256 amount, uint256 indexed taskId);

    // --- Modifiers ---

    modifier onlyArbitrator() {
        require(msg.sender == arbitrator, "Caller is not the arbitrator");
        _;
    }

    modifier requireTaskStatus(uint256 _taskId, TaskStatus _status) {
        require(tasks[_taskId].status == _status, "Task is not in the required status");
        _;
    }

    modifier requireTaskRequestor(uint256 _taskId) {
        require(tasks[_taskId].requestor == msg.sender, "Caller is not the task requestor");
        _;
    }

    modifier requireTaskAssignedProvider(uint256 _taskId) {
        require(tasks[_taskId].assignedProvider == msg.sender, "Caller is not the assigned provider");
        _;
    }

    // --- Constructor ---

    constructor(address _erc20Token, address _arbitrator, uint256 _minRequestorStake, uint256 _minProviderStake, uint256 _disputeFee, uint256 _slashingPercentage) Ownable(msg.sender) {
        require(_erc20Token != address(0), "ERC20 token address cannot be zero");
        require(_arbitrator != address(0), "Arbitrator address cannot be zero");
        require(_slashingPercentage <= 100, "Slashing percentage cannot exceed 100");

        erc20Token = IERC20(_erc20Token);
        arbitrator = _arbitrator;
        minRequestorStake = _minRequestorStake;
        minProviderStake = _minProviderStake;
        disputeFee = _disputeFee;
        slashingPercentage = _slashingPercentage;
        nextTaskId = 1; // Start task IDs from 1
    }

    // --- Provider Management Functions ---

    /// @notice Allows an address to register as a compute provider.
    function registerProvider() external {
        require(!isRegisteredProvider[msg.sender], "Provider already registered");
        providers[msg.sender] = Provider(msg.sender, 0, false); // Start with 0 reputation, inactive
        isRegisteredProvider[msg.sender] = true;
        emit ProviderRegistered(msg.sender);
    }

    /// @notice Allows a registered provider to set their active status.
    /// @param _isActive The desired active status (true to be available for bids, false otherwise).
    function setProviderActiveStatus(bool _isActive) external {
        require(isRegisteredProvider[msg.sender], "Caller is not a registered provider");
        providers[msg.sender].isActive = _isActive;
        emit ProviderStatusChanged(msg.sender, _isActive);
    }

    /// @notice Gets the details of a registered provider.
    /// @param _provider The address of the provider.
    /// @return providerAddress The address of the provider.
    /// @return reputationScore The provider's reputation score.
    /// @return isActive The provider's active status.
    function getProviderDetails(address _provider) external view returns (address providerAddress, int256 reputationScore, bool isActive) {
        require(isRegisteredProvider[_provider], "Provider not registered");
        Provider storage p = providers[_provider];
        return (p.providerAddress, p.reputationScore, p.isActive);
    }

     /// @notice Gets the reputation score of a registered provider.
     /// @param _provider The address of the provider.
     /// @return The provider's reputation score.
    function getProviderReputation(address _provider) external view returns (int256) {
        require(isRegisteredProvider[_provider], "Provider not registered");
        return providers[_provider].reputationScore;
    }

    /// @notice Checks if an address is a registered provider.
    /// @param _provider The address to check.
    /// @return True if registered, false otherwise.
    function isProviderRegistered(address _provider) external view returns (bool) {
        return isRegisteredProvider[_provider];
    }

    // --- Task Lifecycle Functions ---

    /// @notice Creates a new compute task, requires requestor stake.
    /// @param _maxPrice The maximum price the requestor is willing to pay.
    /// @param _duration The maximum time allowed for the provider to complete the task after acceptance (in seconds).
    /// @param _dataURI URI pointing to the task's input data or specification.
    function createComputeTask(uint256 _maxPrice, uint64 _duration, string memory _dataURI) external nonReentrant {
        require(_maxPrice > 0, "Max price must be greater than zero");
        require(_duration > 0, "Duration must be greater than zero");
        require(erc20Token.balanceOf(msg.sender) >= minRequestorStake + _maxPrice, "Insufficient token balance for stake and max price");

        uint256 taskId = nextTaskId++;
        
        // Transfer and lock requestor stake
        require(erc20Token.transferFrom(msg.sender, address(this), minRequestorStake), "Stake transfer failed");
        emit StakeLocked(msg.sender, minRequestorStake, taskId);

        // Task is initially Open, requestor must approve maxPrice *before* calling this
        // Contract will pull maxPrice amount + stake when accepting a bid, but only locks stake initially
        // Alternative: Lock maxPrice + stake on creation. Let's lock only stake initially, pull maxPrice on acceptance.
        // Need to ensure allowance for maxPrice + stake *before* calling this function, or handle pull later.
        // Let's lock stake on creation, and ensure allowance for maxPrice before acceptBid.
        // For simplicity in this example, let's require approval for stake amount before calling this.

        tasks[taskId].id = taskId;
        tasks[taskId].requestor = msg.sender;
        tasks[taskId].maxPrice = _maxPrice;
        tasks[taskId].duration = _duration;
        tasks[taskId].dataURI = _dataURI;
        tasks[taskId].status = TaskStatus.Open;
        tasks[taskId].requestorStake = minRequestorStake;
        // providerStake, acceptedPrice, deadline, assignedProvider, resultURI, proofDetails are set later

        requestorTaskIds[msg.sender].push(taskId);

        emit TaskCreated(taskId, msg.sender, _maxPrice, _duration, _dataURI);
    }

    /// @notice Allows a registered, active provider to bid on an open task.
    /// @param _taskId The ID of the task to bid on.
    /// @param _price The bid price in ERC20 tokens.
    /// @param _eta Estimated time to completion in seconds.
    function bidOnTask(uint256 _taskId, uint256 _price, uint64 _eta) external nonReentrant {
        Task storage task = tasks[_taskId];
        require(task.id != 0, "Task does not exist"); // Check if task exists
        require(task.status == TaskStatus.Open || task.status == TaskStatus.Bidding, "Task is not open for bidding");
        require(isRegisteredProvider[msg.sender], "Caller is not a registered provider");
        require(providers[msg.sender].isActive, "Provider is not active");
        require(msg.sender != task.requestor, "Requestor cannot bid on their own task");
        require(_price > 0 && _price <= task.maxPrice, "Bid price must be greater than zero and less than or equal to max price");
        require(_eta > 0, "ETA must be greater than zero");
        require(erc20Token.balanceOf(msg.sender) >= minProviderStake, "Insufficient token balance for stake");

        // Check if provider already bid on this task to prevent multiple bids
        for (uint i = 0; i < task.bidderAddresses.length; i++) {
             if (task.bidderAddresses[i] == msg.sender) {
                 revert("Provider already placed a bid on this task");
             }
         }

        // Transfer and lock provider stake for this bid
        require(erc20Token.transferFrom(msg.sender, address(this), minProviderStake), "Bid stake transfer failed");
        emit StakeLocked(msg.sender, minProviderStake, _taskId);

        task.bids[msg.sender] = Bid(msg.sender, _price, _eta, minProviderStake);
        task.bidderAddresses.push(msg.sender); // Store bidder address
        task.status = TaskStatus.Bidding; // Task moves to Bidding status once first bid arrives

        emit BidPlaced(_taskId, msg.sender, _price, _eta);
    }

    /// @notice Allows the task requestor to accept a bid from a specific provider.
    /// @param _taskId The ID of the task.
    /// @param _provider The address of the provider whose bid is accepted.
    function acceptBid(uint256 _taskId, address _provider) external nonReentrant requireTaskRequestor(_taskId) {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.Bidding, "Task is not in bidding status");
        require(task.bids[_provider].provider != address(0), "Provider did not place a valid bid");
        require(erc20Token.balanceOf(msg.sender) >= task.bids[_provider].price, "Requestor insufficient balance for payment");
        
        // Unlock stakes from losing bidders
        for (uint i = 0; i < task.bidderAddresses.length; i++) {
            address bidder = task.bidderAddresses[i];
            if (bidder != _provider) {
                Bid storage losingBid = task.bids[bidder];
                if (losingBid.stake > 0) { // Ensure stake was actually placed
                    require(erc20Token.transfer(bidder, losingBid.stake), "Failed to return losing bid stake");
                    emit StakeReleased(bidder, losingBid.stake, _taskId);
                    losingBid.stake = 0; // Mark stake as returned
                }
            }
        }
        // Clear bidder addresses array (or just mark as processed) - clearing is simpler
        delete task.bidderAddresses; // This clears the dynamic array

        // Get the accepted bid details
        Bid storage acceptedBid = task.bids[_provider];

        // Transfer and lock payment amount from requestor
        require(erc20Token.transferFrom(msg.sender, address(this), acceptedBid.price), "Payment transfer failed");
        emit StakeLocked(msg.sender, acceptedBid.price, _taskId); // Locking payment as well

        task.assignedProvider = _provider;
        task.acceptedPrice = acceptedBid.price;
        task.providerStake = acceptedBid.stake; // Transfer ownership of this stake to the assigned task
        task.deadline = block.timestamp + acceptedBid.eta;
        task.status = TaskStatus.Assigned;

        providerAssignedTaskIds[_provider].push(_taskId);

        emit BidAccepted(_taskId, msg.sender, _provider, acceptedBid.price);
    }

    /// @notice Allows the assigned provider to submit proof of task completion.
    /// @param _taskId The ID of the task.
    /// @param _resultURI URI pointing to the computation result.
    /// @param _proofDetails Details/hash for verification proof (e.g., IPFS hash of a ZK proof file).
    function submitResultProof(uint256 _taskId, string memory _resultURI, string memory _proofDetails) external nonReentrant requireTaskAssignedProvider(_taskId) requireTaskStatus(_taskId, TaskStatus.Assigned) {
        Task storage task = tasks[_taskId];
        // Allow submission slightly after deadline, but mark for potential expiration handling
        // require(block.timestamp <= task.deadline, "Submission deadline passed"); // Strict check

        task.resultURI = _resultURI;
        task.proofDetails = _proofDetails;
        task.status = TaskStatus.ProofSubmitted;

        emit ResultProofSubmitted(_taskId, msg.sender, _resultURI);
    }

    /// @notice Allows the task requestor to confirm the result is satisfactory, triggering payment and stake release.
    /// @param _taskId The ID of the task.
    function confirmTaskCompletion(uint256 _taskId) external nonReentrant requireTaskRequestor(_taskId) requireTaskStatus(_taskId, TaskStatus.ProofSubmitted) {
        Task storage task = tasks[_taskId];
        require(block.timestamp <= task.deadline + task.duration, "Confirmation deadline passed"); // Give requestor some time to confirm

        // Payout to provider
        uint256 payoutAmount = task.acceptedPrice;
        require(erc20Token.transfer(task.assignedProvider, payoutAmount), "Payment transfer failed");
        emit FundsTransferred(address(this), task.assignedProvider, payoutAmount, _taskId);

        // Release stakes
        require(erc20Token.transfer(task.requestor, task.requestorStake), "Requestor stake release failed");
        emit StakeReleased(task.requestor, task.requestorStake, _taskId);

        require(erc20Token.transfer(task.assignedProvider, task.providerStake), "Provider stake release failed");
        emit StakeReleased(task.assignedProvider, task.providerStake, _taskId);

        // Update provider reputation (positive)
        providers[task.assignedProvider].reputationScore += 1;

        task.status = TaskStatus.Completed;

        emit TaskCompleted(_taskId, msg.sender, task.assignedProvider, payoutAmount);
    }

    /// @notice Allows the requestor to cancel an open task before a bid is accepted.
    /// @param _taskId The ID of the task.
    function cancelTask(uint256 _taskId) external nonReentrant requireTaskRequestor(_taskId) {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.Open || task.status == TaskStatus.Bidding, "Task cannot be cancelled in current status");

        // Return requestor stake
        require(erc20Token.transfer(msg.sender, task.requestorStake), "Requestor stake release failed on cancel");
        emit StakeReleased(msg.sender, task.requestorStake, _taskId);

        // Return provider stakes if in Bidding state
        if (task.status == TaskStatus.Bidding) {
             for (uint i = 0; i < task.bidderAddresses.length; i++) {
                address bidder = task.bidderAddresses[i];
                Bid storage bid = task.bids[bidder];
                 if (bid.stake > 0) {
                     require(erc20Token.transfer(bidder, bid.stake), "Failed to return bidder stake on cancel");
                     emit StakeReleased(bidder, bid.stake, _taskId);
                     bid.stake = 0; // Mark as returned
                 }
             }
             delete task.bidderAddresses;
        }

        task.status = TaskStatus.Cancelled;

        emit TaskCancelled(_taskId, msg.sender);
    }

    /// @notice Allows either the requestor or the assigned provider to raise a dispute.
    /// Requires locking a dispute fee.
    /// @param _taskId The ID of the task.
    function raiseDispute(uint256 _taskId) external nonReentrant {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.Assigned || task.status == TaskStatus.ProofSubmitted, "Dispute can only be raised in Assigned or ProofSubmitted status");
        require(msg.sender == task.requestor || msg.sender == task.assignedProvider, "Only requestor or assigned provider can raise a dispute");
        require(task.disputeFeeStake == 0, "Dispute already raised");
        require(erc20Token.balanceOf(msg.sender) >= disputeFee, "Insufficient token balance for dispute fee");

        // Transfer and lock dispute fee
        require(erc20Token.transferFrom(msg.sender, address(this), disputeFee), "Dispute fee transfer failed");
        emit StakeLocked(msg.sender, disputeFee, _taskId);

        task.disputeFeeStake = disputeFee;
        task.status = TaskStatus.Disputed;

        emit DisputeRaised(_taskId, msg.sender);
    }

    /// @notice Allows the arbitrator to resolve a dispute.
    /// Distributes stakes and potentially slashes the loser.
    /// @param _taskId The ID of the task.
    /// @param _winner The address of the party who won the dispute (requestor or provider).
    function arbitrateDispute(uint256 _taskId, address _winner) external nonReentrant onlyArbitrator requireTaskStatus(_taskId, TaskStatus.Disputed) {
        Task storage task = tasks[_taskId];
        require(_winner == task.requestor || _winner == task.assignedProvider, "Winner must be either the requestor or the assigned provider");
        address loser = (_winner == task.requestor) ? task.assignedProvider : task.requestor;

        // Return dispute fee to the winner
        require(erc20Token.transfer(_winner, task.disputeFeeStake), "Dispute fee return failed");
        emit StakeReleased(_winner, task.disputeFeeStake, _taskId);
        task.disputeFeeStake = 0; // Mark as returned

        // Handle stakes based on winner/loser
        uint256 requestorStakeAmount = task.requestorStake;
        uint256 providerStakeAmount = task.providerStake;
        uint256 slashedAmount = 0;

        if (_winner == task.requestor) {
            // Requestor wins: Requestor stake returned, Provider stake slashed
            require(erc20Token.transfer(task.requestor, requestorStakeAmount), "Requestor stake return failed after arbitration");
            emit StakeReleased(task.requestor, requestorStakeAmount, _taskId);

            slashedAmount = (providerStakeAmount * slashingPercentage) / 100;
            uint256 providerRefund = providerStakeAmount - slashedAmount;
            if (providerRefund > 0) {
                 require(erc20Token.transfer(task.assignedProvider, providerRefund), "Provider partial stake return failed after arbitration");
                 emit StakeReleased(task.assignedProvider, providerRefund, _taskId);
            }
            if (slashedAmount > 0) {
                // Slashed funds remain in the contract or are sent to a treasury/burn address
                // For simplicity, they remain in the contract balance in this example.
                emit StakeSlashed(task.assignedProvider, slashedAmount, _taskId);
            }

            // Update reputation (negative for provider)
            providers[task.assignedProvider].reputationScore -= 1;

        } else { // _winner == task.assignedProvider
            // Provider wins: Provider stake returned, Requestor stake returned, Payout made
            require(erc20Token.transfer(task.requestor, requestorStakeAmount), "Requestor stake return failed after arbitration");
            emit StakeReleased(task.requestor, requestorStakeAmount, _taskId);

            require(erc20Token.transfer(task.assignedProvider, providerStakeAmount), "Provider stake return failed after arbitration");
            emit StakeReleased(task.assignedProvider, providerStakeAmount, _taskId);

            // Payout to provider
            uint256 payoutAmount = task.acceptedPrice;
            require(erc20Token.transfer(task.assignedProvider, payoutAmount), "Payment transfer failed after arbitration");
            emit FundsTransferred(address(this), task.assignedProvider, payoutAmount, _taskId);

             // Update reputation (positive for provider, neutral for requestor)
            providers[task.assignedProvider].reputationScore += 1;
        }

        task.requestorStake = 0; // Mark as zero after distribution
        task.providerStake = 0; // Mark as zero after distribution
        task.status = TaskStatus.Completed; // Mark as completed (resolved)

        emit DisputeArbitrated(_taskId, _winner, loser);
    }

     /// @notice Allows anyone to trigger expiration handling for a task past its deadline.
     /// Applies only if the task is Assigned or ProofSubmitted and the deadline has passed.
     /// Slashes provider stake if proof wasn't submitted in time.
     /// @param _taskId The ID of the task.
    function handleTaskExpiration(uint256 _taskId) external nonReentrant {
        Task storage task = tasks[_taskId];
        require(task.id != 0, "Task does not exist");
        require(task.status == TaskStatus.Assigned || task.status == TaskStatus.ProofSubmitted, "Task not in an expirable state");
        require(block.timestamp > task.deadline, "Task deadline has not passed");

        // Return requestor stake
        require(erc20Token.transfer(task.requestor, task.requestorStake), "Requestor stake release failed on expiration");
        emit StakeReleased(task.requestor, task.requestorStake, _taskId);
        task.requestorStake = 0;

        // Handle provider stake
        uint256 providerStakeAmount = task.providerStake;
        uint256 slashedAmount = 0;

        if (task.status == TaskStatus.Assigned) {
            // Provider failed to submit proof by deadline
            slashedAmount = (providerStakeAmount * slashingPercentage) / 100;
            uint256 providerRefund = providerStakeAmount - slashedAmount;
            if (providerRefund > 0) {
                 require(erc20Token.transfer(task.assignedProvider, providerRefund), "Provider partial stake return failed on expiration");
                 emit StakeReleased(task.assignedProvider, providerRefund, _taskId);
            }
             if (slashedAmount > 0) {
                emit StakeSlashed(task.assignedProvider, slashedAmount, _taskId);
            }
            // Update reputation (negative)
            providers[task.assignedProvider].reputationScore -= 1;

        } else if (task.status == TaskStatus.ProofSubmitted) {
            // Requestor failed to confirm in time after provider submitted proof by deadline (assuming a grace period)
            // Or, less likely, requestor disputes after deadline but before arbitrator rules.
            // Simplification: If provider submitted proof by deadline, provider stake is returned, requestor stake returned.
            // A more complex system might involve auto-completion if proof is valid and requestor is non-responsive.
            // Let's implement the simple version: Stakes are returned if proof was submitted on time.
            // We need to check if proof was submitted *before* the deadline. This requires storing the submission time.
            // Let's modify submitResultProof to store submission time.
            // Adding `uint64 submissionTime` to Task struct.

            // Re-evaluate: If task is in ProofSubmitted *and* deadline passed, it implies provider submitted
            // proof *before* or *at* the deadline (or we allow slight delay). If requestor didn't confirm, it could
            // be requestor fault or proof was bad. Arbitration is the clean path here.
            // Let's simplify: If expiration is called in ProofSubmitted, it means requestor didn't confirm/dispute in time.
            // Provider gets stake back. Requestor gets stake back. No payout.
             require(erc20Token.transfer(task.assignedProvider, providerStakeAmount), "Provider stake return failed on expiration (ProofSubmitted)");
             emit StakeReleased(task.assignedProvider, providerStakeAmount, _taskId);

             // Reputation is neutral in this specific expiration case (ProofSubmitted)
        }
         task.providerStake = 0;
         task.status = TaskStatus.Expired;

         emit TaskExpired(_taskId);
    }

    /// @notice Allows a user to withdraw released stakes or funds.
    /// This isn't strictly necessary if transfers happen automatically, but useful if funds might get stuck.
    /// Current implementation transfers automatically, so this might not be callable unless designed differently.
    /// Keeping as a placeholder/potential escape hatch if needed.
    // function withdrawStake(uint256 _taskId) external {
    //     // This function would require complex state tracking of 'releasable' funds per user per task.
    //     // Given the current design transfers funds immediately upon resolution/completion,
    //     // this function is not directly usable as described.
    //     // A different design (e.g., pull pattern for all payouts) would enable this.
    //     revert("Withdrawal function not applicable with current push payment design");
    // }


    // --- Query Functions (View) ---

    /// @notice Gets all details of a specific task.
    /// @param _taskId The ID of the task.
    /// @return A tuple containing task details. Note: bids mapping cannot be returned directly.
    function getTaskDetails(uint256 _taskId) external view returns (
        uint256 id,
        address requestor,
        address assignedProvider,
        uint256 maxPrice,
        uint256 acceptedPrice,
        uint64 duration,
        uint64 deadline,
        string memory dataURI,
        string memory resultURI,
        string memory proofDetails,
        TaskStatus status,
        uint256 requestorStake,
        uint256 providerStake,
        uint256 disputeFeeStake
    ) {
        Task storage task = tasks[_taskId];
         require(task.id != 0, "Task does not exist");
        return (
            task.id,
            task.requestor,
            task.assignedProvider,
            task.maxPrice,
            task.acceptedPrice,
            task.duration,
            task.deadline,
            task.dataURI,
            task.resultURI,
            task.proofDetails,
            task.status,
            task.requestorStake,
            task.providerStake,
            task.disputeFeeStake
        );
    }

    /// @notice Gets all bids placed on a specific task.
    /// @param _taskId The ID of the task.
    /// @return An array of Bid structs.
    function getTaskBids(uint256 _taskId) external view returns (Bid[] memory) {
         Task storage task = tasks[_taskId];
         require(task.id != 0, "Task does not exist");
         Bid[] memory bidsArray = new Bid[](task.bidderAddresses.length);
         for (uint i = 0; i < task.bidderAddresses.length; i++) {
             bidsArray[i] = task.bids[task.bidderAddresses[i]];
         }
         return bidsArray;
    }

    /// @notice Gets the current status of a task.
    /// @param _taskId The ID of the task.
    /// @return The TaskStatus enum value.
    function getTaskStatus(uint256 _taskId) external view returns (TaskStatus) {
        require(tasks[_taskId].id != 0, "Task does not exist");
        return tasks[_taskId].status;
    }

    /// @notice Gets the stake information for a task.
    /// @param _taskId The ID of the task.
    /// @return requestorStake Amount staked by the requestor.
    /// @return providerStake Amount staked by the assigned provider.
    /// @return disputeFeeStake Amount staked for dispute resolution.
    function getTaskStakeInfo(uint256 _taskId) external view returns (uint256 requestorStake, uint256 providerStake, uint256 disputeFeeStake) {
         require(tasks[_taskId].id != 0, "Task does not exist");
         Task storage task = tasks[_taskId];
         return (task.requestorStake, task.providerStake, task.disputeFeeStake);
    }

    /// @notice Gets the number of bids placed on a task.
    /// @param _taskId The ID of the task.
    /// @return The number of bids.
    function getTaskBidsCount(uint256 _taskId) external view returns (uint256) {
        require(tasks[_taskId].id != 0, "Task does not exist");
        return tasks[_taskId].bidderAddresses.length;
    }

    /// @notice Gets the URI for the result of a task.
    /// @param _taskId The ID of the task.
    /// @return The result URI string.
    function getTaskResultURI(uint256 _taskId) external view returns (string memory) {
        require(tasks[_taskId].id != 0, "Task does not exist");
        // Only reveal result URI if status is ProofSubmitted or later
        require(tasks[_taskId].status >= TaskStatus.ProofSubmitted, "Result URI not available yet");
        return tasks[_taskId].resultURI;
    }

    /// @notice Gets the array of task IDs created by a specific requestor.
    /// @param _requestor The address of the requestor.
    /// @return An array of task IDs.
    function getTasksByRequestor(address _requestor) external view returns (uint256[] memory) {
        return requestorTaskIds[_requestor];
    }

     /// @notice Gets the array of task IDs assigned to a specific provider.
     /// @param _provider The address of the provider.
     /// @return An array of task IDs.
    function getTasksByProvider(address _provider) external view returns (uint256[] memory) {
        return providerAssignedTaskIds[_provider];
    }

    /// @notice Gets the current arbitrator address.
    /// @return The arbitrator address.
    function getArbitrator() external view returns (address) {
        return arbitrator;
    }

    /// @notice Gets the current minimum staking amounts.
    /// @return minReqStake Minimum stake for requestors.
    /// @return minProvStake Minimum stake for providers.
    function getMinimumStakes() external view returns (uint256 minReqStake, uint256 minProvStake) {
        return (minRequestorStake, minProviderStake);
    }

    /// @notice Gets the current dispute fee.
    /// @return The dispute fee amount.
    function getDisputeFee() external view returns (uint256) {
        return disputeFee;
    }

    /// @notice Gets the current slashing percentage.
    /// @return The slashing percentage (0-100).
    function getSlashingPercentage() external view returns (uint256) {
        return slashingPercentage;
    }

    // --- Admin Functions ---

    /// @notice Allows the owner to change the arbitrator address.
    /// @param _newArbitrator The address of the new arbitrator.
    function setArbitrator(address _newArbitrator) external onlyOwner {
        require(_newArbitrator != address(0), "New arbitrator address cannot be zero");
        arbitrator = _newArbitrator;
    }

    /// @notice Allows the owner to set the minimum staking amounts.
    /// @param _minReqStake Minimum stake required for requestors.
    /// @param _minProvStake Minimum stake required for providers.
    function setMinimumStakes(uint256 _minReqStake, uint256 _minProvStake) external onlyOwner {
        minRequestorStake = _minReqStake;
        minProviderStake = _minProvStake;
    }

    /// @notice Allows the owner to set the dispute fee.
    /// @param _disputeFee The new dispute fee amount.
    function setDisputeFee(uint256 _disputeFee) external onlyOwner {
        disputeFee = _disputeFee;
    }

    /// @notice Allows the owner to set the slashing percentage.
    /// @param _slashingPercentage The new slashing percentage (0-100).
    function setSlashingPercentage(uint256 _slashingPercentage) external onlyOwner {
        require(_slashingPercentage <= 100, "Slashing percentage cannot exceed 100");
        slashingPercentage = _slashingPercentage;
    }

    // Fallback function to prevent accidental ETH sends
    receive() external payable {
        revert("ETH not accepted");
    }

    fallback() external payable {
        revert("Call not accepted");
    }
}
```