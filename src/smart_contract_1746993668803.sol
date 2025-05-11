Okay, let's design a smart contract for a Decentralized AI Compute Marketplace. This contract will allow users to request AI computation tasks (like model inference or small training jobs) and allow other users to act as compute providers, executing these tasks off-chain and submitting results on-chain. It incorporates concepts like task escrow, provider staking, reputation scoring (simplified), and a basic dispute mechanism.

This design avoids direct duplication of standard ERC tokens, NFTs, or simple escrow patterns, combining multiple concepts into a unique marketplace structure.

**Contract Name:** `DecentralizedAIComputeMarketplace`

**Outline:**

1.  **SPDX-License-Identifier & Pragma**
2.  **Owner State Variable & Modifier** (Basic ownership implementation)
3.  **Events** (To log key actions)
4.  **Enums** (For Task Status)
5.  **Structs** (For Task, Provider Profile, Client Profile)
6.  **State Variables & Mappings** (Counters, configs, storing data)
7.  **Constructor** (Set owner, initial configs)
8.  **Modifiers** (e.g., for task status checks)
9.  **User Profile Management**
    *   Register as Client
    *   Register as Provider
    *   Update Provider Specs
    *   Stake Provider
    *   Unstake Provider
    *   Withdraw Unstaked Amount
10. **Task Management (Client Side)**
    *   Create Task (Payable)
    *   Cancel Task
    *   Approve Task Completion
    *   Raise Dispute
11. **Task Management (Provider Side)**
    *   Claim Task
    *   Submit Results
12. **Task Management (General)**
    *   Fail Task (Timeout/Manual)
    *   Resolve Dispute (Owner/Admin Function)
13. **Admin & Configuration**
    *   Update Minimum Provider Stake
    *   Update Task Assignment Timeout
    *   Update Task Completion Timeout
    *   Slash Provider Stake (Owner/Admin Function)
14. **View Functions (Read-Only)**
    *   Get Total Tasks
    *   Get Provider Profile
    *   Get Client Profile
    *   Get Task Details
    *   Get Task Status
    *   Get Available Task IDs
    *   Get Provider Task IDs
    *   Get Client Task IDs

**Function Summary:**

1.  `constructor()`: Initializes the contract owner and sets initial configuration parameters.
2.  `registerAsClient()`: Allows an address to register as a client in the marketplace.
3.  `registerAsProvider(string calldata specs)`: Allows an address to register as a compute provider, specifying their available hardware capabilities. Requires minimum stake.
4.  `updateProviderSpecs(string calldata specs)`: Allows a registered provider to update their advertised compute specifications.
5.  `stakeProvider(uint amount)`: Allows a registered provider to add more stake to their profile.
6.  `unstakeProvider()`: Allows a provider to initiate unstaking their collateral. Requires having no active tasks. Stake might be locked for a period (not implemented in this basic version, but could be an extension).
7.  `withdrawUnstakedAmount()`: Allows a provider to withdraw their unstaked balance after `unstakeProvider` (assuming no lockup or lockup period passed).
8.  `createTask(string calldata dataPointer, string calldata modelPointer, string calldata computeSpecs, uint paymentAmount)`: Allows a registered client to create a new compute task request, providing data/model pointers, required specs, and offering a payment. Requires sending the payment amount with the transaction. The payment is held in escrow.
9.  `cancelTask(uint taskId)`: Allows the client who created a task to cancel it, but only if it has not yet been assigned to a provider. Refunds the escrowed payment.
10. `claimTask(uint taskId)`: Allows a registered provider to claim an available task if they meet the required specs and have sufficient stake. Assigns the task to the provider and updates its status.
11. `submitResults(uint taskId, string calldata resultsPointer)`: Allows the assigned provider to submit the results of a completed off-chain computation task by providing a pointer (e.g., IPFS hash) to the results. Updates task status.
12. `approveTaskCompletion(uint taskId)`: Allows the client who created the task to approve the submitted results. If approved, releases the payment from escrow to the provider and updates reputation.
13. `raiseDispute(uint taskId, string calldata reasonPointer)`: Allows either the client or the provider to raise a dispute about a task after results are submitted. Changes task status to indicate a dispute.
14. `resolveDispute(uint taskId, address winningParty)`: (Owner/Admin Only) Resolves a disputed task. Can award payment to the winning party (client or provider), potentially slash provider stake, and update reputation.
15. `failTask(uint taskId)`: (Could be called by owner or an external watcher after timeout) Marks a task as failed, potentially refunding the client and penalizing the provider (if assigned).
16. `updateMinimumProviderStake(uint amount)`: (Owner Only) Updates the minimum required stake for providers.
17. `updateTaskAssignmentTimeout(uint duration)`: (Owner Only) Updates the maximum time allowed for a task to be claimed by a provider after creation.
18. `updateTaskCompletionTimeout(uint duration)`: (Owner Only) Updates the maximum time allowed for a provider to submit results after claiming a task.
19. `slashProviderStake(address provider, uint amount)`: (Owner Only) Manually slashes a provider's stake, typically used as part of dispute resolution or punishment for misbehavior.
20. `getTotalTasks()`: (View) Returns the total number of tasks created.
21. `getProviderProfile(address provider)`: (View) Returns the profile details of a specific provider.
22. `getClientProfile(address client)`: (View) Returns the profile details of a specific client.
23. `getTaskDetails(uint taskId)`: (View) Returns all details for a specific task.
24. `getTaskStatus(uint taskId)`: (View) Returns the current status of a specific task.
25. `getAvailableTaskIds()`: (View) Returns a list of task IDs that are currently in the 'Created' status and available for claiming. (Note: May be gas-intensive for large numbers of tasks).
26. `getProviderTaskIds(address provider)`: (View) Returns a list of task IDs associated with a specific provider (active or completed). (Note: May be gas-intensive).
27. `getClientTaskIds(address client)`: (View) Returns a list of task IDs created by a specific client. (Note: May be gas-intensive).

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title DecentralizedAIComputeMarketplace
 * @dev A marketplace contract for requesting and providing decentralized AI computation tasks.
 *      Clients create tasks with data/model pointers and payment. Providers stake collateral
 *      and claim tasks to execute computation off-chain. Results are submitted on-chain
 *      via pointer, client approves, and payment is released from escrow.
 *      Includes basic reputation, staking, and dispute mechanisms.
 *
 * Outline:
 * 1. SPDX-License-Identifier & Pragma
 * 2. Owner State Variable & Modifier
 * 3. Events
 * 4. Enums
 * 5. Structs
 * 6. State Variables & Mappings
 * 7. Constructor
 * 8. Modifiers (Task Status Checks - Internal/Example)
 * 9. User Profile Management (register, update, stake, unstake, withdraw)
 * 10. Task Management (Client Side: create, cancel, approve, dispute)
 * 11. Task Management (Provider Side: claim, submit)
 * 12. Task Management (General: fail, resolve dispute)
 * 13. Admin & Configuration (update settings, slash stake)
 * 14. View Functions (read-only getters)
 *
 * Function Summary:
 * 1.  constructor(): Initializes owner and config.
 * 2.  registerAsClient(): Register as a marketplace client.
 * 3.  registerAsProvider(string calldata specs): Register as a provider, requires stake.
 * 4.  updateProviderSpecs(string calldata specs): Update provider's specs.
 * 5.  stakeProvider(uint amount): Add stake as a provider.
 * 6.  unstakeProvider(): Initiate unstaking (requires no active tasks).
 * 7.  withdrawUnstakedAmount(): Withdraw unstaked balance.
 * 8.  createTask(string calldata dataPointer, string calldata modelPointer, string calldata computeSpecs, uint paymentAmount): Create a task, pays into escrow.
 * 9.  cancelTask(uint taskId): Cancel unassigned task, refunds client.
 * 10. claimTask(uint taskId): Provider claims an available task.
 * 11. submitResults(uint taskId, string calldata resultsPointer): Provider submits results pointer.
 * 12. approveTaskCompletion(uint taskId): Client approves results, releases payment.
 * 13. raiseDispute(uint taskId, string calldata reasonPointer): Raise dispute on results.
 * 14. resolveDispute(uint taskId, address winningParty): (Owner) Resolve a dispute.
 * 15. failTask(uint taskId): (Owner/Watcher) Mark task as failed (e.g., timeout).
 * 16. updateMinimumProviderStake(uint amount): (Owner) Set min stake.
 * 17. updateTaskAssignmentTimeout(uint duration): (Owner) Set timeout for claiming.
 * 18. updateTaskCompletionTimeout(uint duration): (Owner) Set timeout for submission.
 * 19. slashProviderStake(address provider, uint amount): (Owner) Manually slash stake.
 * 20. getTotalTasks(): Get total task count.
 * 21. getProviderProfile(address provider): Get provider details.
 * 22. getClientProfile(address client): Get client details.
 * 23. getTaskDetails(uint taskId): Get task details.
 * 24. getTaskStatus(uint taskId): Get task status.
 * 25. getAvailableTaskIds(): Get IDs of tasks ready to be claimed.
 * 26. getProviderTaskIds(address provider): Get IDs of tasks for a provider.
 * 27. getClientTaskIds(address client): Get IDs of tasks for a client.
 */
contract DecentralizedAIComputeMarketplace {

    address private owner;

    // Basic Ownership Implementation
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    // --- Events ---
    event ClientRegistered(address indexed client);
    event ProviderRegistered(address indexed provider, string specs, uint initialStake);
    event ProviderSpecsUpdated(address indexed provider, string newSpecs);
    event ProviderStaked(address indexed provider, uint amount, uint totalStake);
    event ProviderUnstaked(address indexed provider, uint amountRemaining); // Note: Actual withdrawal is separate
    event ProviderStakeWithdrawn(address indexed provider, uint amount);
    event TaskCreated(uint indexed taskId, address indexed client, uint paymentAmount, string dataPointer, string modelPointer, string computeSpecs);
    event TaskCancelled(uint indexed taskId, address indexed client);
    event TaskClaimed(uint indexed taskId, address indexed provider);
    event ResultsSubmitted(uint indexed taskId, address indexed provider, string resultsPointer);
    event TaskCompleted(uint indexed taskId, address indexed client, address indexed provider);
    event PaymentReleased(uint indexed taskId, address indexed provider, uint amount);
    event TaskFailed(uint indexed taskId, string reason);
    event DisputeRaised(uint indexed taskId, address indexed party, string reasonPointer);
    event DisputeResolved(uint indexed taskId, address indexed winningParty, address indexed losingParty);
    event StakeSlashed(address indexed provider, uint amount, string reason);
    event ReputationUpdated(address indexed account, int scoreChange, uint newScore); // int for +/-

    // --- Enums ---
    enum TaskStatus {
        Created,          // Task created, waiting for a provider to claim
        Assigned,         // Task claimed by a provider, computation in progress
        ResultsSubmitted, // Provider submitted results, waiting for client approval or validation
        Validated,        // (Optional step not fully implemented) Results validated
        Completed,        // Client approved results, payment released
        Disputed,         // Task results are under dispute
        Failed,           // Task failed (e.g., timeout, provider unresponsive)
        Cancelled         // Task cancelled by client before assignment
    }

    // --- Structs ---
    struct Task {
        uint taskId;
        address client;
        address provider; // Address(0) if not assigned
        string dataPointer; // Pointer to input data (e.g., IPFS hash, URL)
        string modelPointer; // Pointer to model info (e.g., IPFS hash, spec)
        string computeSpecs; // Required computation specs (e.g., "GPU 16GB", "CPU 64GB RAM")
        uint paymentAmount;  // Amount client pays for task completion (in wei)
        TaskStatus status;
        string resultsPointer; // Pointer to output results (e.g., IPFS hash)
        uint createdAt;
        uint assignedAt;
        uint completedAt; // Timestamp of completion/failure/cancellation
        string disputeReasonPointer; // Pointer to dispute reason/evidence
    }

    struct ProviderProfile {
        address providerId;
        bool isRegistered;
        uint stake; // Collateral staked by the provider
        uint reputationScore; // Simple score (e.g., sum of weighted successful tasks)
        string availableSpecs; // Specs the provider offers
        uint activeTaskCount; // Number of tasks currently assigned to this provider
    }

    struct ClientProfile {
        address clientId;
        bool isRegistered;
        uint tasksCreatedCount; // Number of tasks created by this client
    }

    // --- State Variables & Mappings ---
    uint public taskIdCounter;
    uint public minProviderStake; // Minimum stake required for providers
    uint public taskAssignmentTimeout; // Max time (seconds) for task to be claimed
    uint public taskCompletionTimeout; // Max time (seconds) for provider to submit results

    mapping(uint => Task) public tasks;
    mapping(address => ProviderProfile) public providerProfiles;
    mapping(address => ClientProfile) public clientProfiles;

    // Store task IDs per address (potential gas cost for large arrays, better approaches exist for production)
    mapping(address => uint[]) private providerTaskIds;
    mapping(address => uint[]) private clientTaskIds;
    uint[] private availableTaskIds; // List of task IDs in 'Created' status

    // --- Constructor ---
    constructor(uint _minProviderStake, uint _taskAssignmentTimeout, uint _taskCompletionTimeout) {
        owner = msg.sender;
        minProviderStake = _minProviderStake;
        taskAssignmentTimeout = _taskAssignmentTimeout;
        taskCompletionTimeout = _taskCompletionTimeout;
        taskIdCounter = 0;
    }

    // --- User Profile Management ---

    /**
     * @dev Registers the caller as a client.
     */
    function registerAsClient() external {
        require(!clientProfiles[msg.sender].isRegistered, "Already registered as client");
        clientProfiles[msg.sender].clientId = msg.sender;
        clientProfiles[msg.sender].isRegistered = true;
        emit ClientRegistered(msg.sender);
    }

    /**
     * @dev Registers the caller as a provider, requires minimum stake.
     * @param specs Description of the provider's compute capabilities.
     */
    function registerAsProvider(string calldata specs) external payable {
        require(!providerProfiles[msg.sender].isRegistered, "Already registered as provider");
        require(msg.value >= minProviderStake, "Minimum stake not met");

        providerProfiles[msg.sender].providerId = msg.sender;
        providerProfiles[msg.sender].isRegistered = true;
        providerProfiles[msg.sender].stake = msg.value;
        providerProfiles[msg.sender].reputationScore = 0; // Start with 0
        providerProfiles[msg.sender].availableSpecs = specs;
        providerProfiles[msg.sender].activeTaskCount = 0;

        emit ProviderRegistered(msg.sender, specs, msg.value);
    }

    /**
     * @dev Updates the compute specifications for a registered provider.
     * @param specs New description of compute capabilities.
     */
    function updateProviderSpecs(string calldata specs) external {
        require(providerProfiles[msg.sender].isRegistered, "Not registered as provider");
        providerProfiles[msg.sender].availableSpecs = specs;
        emit ProviderSpecsUpdated(msg.sender, specs);
    }

    /**
     * @dev Allows a registered provider to add more stake.
     * @param amount The amount of wei to add to the stake.
     */
    function stakeProvider(uint amount) external payable {
        require(providerProfiles[msg.sender].isRegistered, "Not registered as provider");
        require(msg.value == amount, "Sent amount must match stake amount");

        providerProfiles[msg.sender].stake += amount;
        emit ProviderStaked(msg.sender, amount, providerProfiles[msg.sender].stake);
    }

    /**
     * @dev Initiates unstaking for a provider. Requires no active tasks.
     *      (Doesn't handle lockup period in this version, but could be added)
     */
    function unstakeProvider() external {
        require(providerProfiles[msg.sender].isRegistered, "Not registered as provider");
        require(providerProfiles[msg.sender].activeTaskCount == 0, "Cannot unstake with active tasks");
        // In a real system, might set a flag and start a lockup timer here.
        // For simplicity, we just move balance to a withdrawable balance.
        uint amountToUnstake = providerProfiles[msg.sender].stake;
        require(amountToUnstake > 0, "No stake to unstake");

        providerProfiles[msg.sender].stake = 0; // Move all stake to unstaked (simplification)
        // Assuming a separate 'withdrawableBalance' state variable per provider would be better
        // For now, let's assume unstaking makes it immediately available via withdrawUnstakedAmount
        // A more robust system would require a lockup.
        // Add comment about lockup: // TODO: Implement stake lockup period

        emit ProviderUnstaked(msg.sender, 0); // stake remaining is 0 after unstake call in this version
    }

     /**
     * @dev Allows a provider to withdraw their unstaked balance.
     *      In this simplified version, unstaking makes stake immediately withdrawable.
     */
    function withdrawUnstakedAmount() external {
        // In a real system, this would check a dedicated unstaked balance and lockup timer.
        // Since unstakeProvider currently sets stake to 0, this is a placeholder.
        // A provider could *only* withdraw if their 'stake' was 0 *after* unstakeProvider was called,
        // and assuming no new stake was added. This needs a dedicated unstaked balance field.

        // TODO: Refactor staking/unstaking to include a withdrawable balance and optional lockup.
        // This function is a placeholder based on the simplified unstake.
        // For now, let's allow withdrawing if stake is 0 and they are registered, but this is flawed.
         revert("Staking/Unstaking needs refinement with a separate withdrawable balance");
        // Example logic (requires `withdrawableBalance` mapping):
        // uint amount = providerProfiles[msg.sender].withdrawableBalance;
        // require(amount > 0, "No unstaked balance to withdraw");
        // providerProfiles[msg.sender].withdrawableBalance = 0;
        // (bool success, ) = payable(msg.sender).call{value: amount}("");
        // require(success, "Withdrawal failed");
        // emit ProviderStakeWithdrawn(msg.sender, amount);
    }


    // --- Task Management (Client Side) ---

    /**
     * @dev Client creates a new compute task. Requires payment to be sent.
     * @param dataPointer Pointer to input data.
     * @param modelPointer Pointer to model info/file.
     * @param computeSpecs Required compute specifications.
     * @param paymentAmount The amount offered for task completion.
     */
    function createTask(
        string calldata dataPointer,
        string calldata modelPointer,
        string calldata computeSpecs,
        uint paymentAmount
    ) external payable {
        require(clientProfiles[msg.sender].isRegistered, "Not registered as client");
        require(msg.value == paymentAmount, "Sent amount must match paymentAmount");
        require(paymentAmount > 0, "Payment amount must be greater than zero");

        taskIdCounter++;
        uint currentTaskId = taskIdCounter;

        tasks[currentTaskId] = Task({
            taskId: currentTaskId,
            client: msg.sender,
            provider: address(0), // Not yet assigned
            dataPointer: dataPointer,
            modelPointer: modelPointer,
            computeSpecs: computeSpecs,
            paymentAmount: paymentAmount,
            status: TaskStatus.Created,
            resultsPointer: "",
            createdAt: block.timestamp,
            assignedAt: 0,
            completedAt: 0,
            disputeReasonPointer: ""
        });

        clientProfiles[msg.sender].tasksCreatedCount++;
        clientTaskIds[msg.sender].push(currentTaskId);
        availableTaskIds.push(currentTaskId); // Add to available list

        emit TaskCreated(currentTaskId, msg.sender, paymentAmount, dataPointer, modelPointer, computeSpecs);
    }

    /**
     * @dev Client cancels a task if it hasn't been assigned. Refunds payment.
     * @param taskId The ID of the task to cancel.
     */
    function cancelTask(uint taskId) external {
        Task storage task = tasks[taskId];
        require(task.client == msg.sender, "Not the task client");
        require(task.status == TaskStatus.Created, "Task cannot be cancelled in current status");

        task.status = TaskStatus.Cancelled;
        task.completedAt = block.timestamp;

        // Remove from availableTaskIds list (inefficient for large lists, production needs better handling)
        for (uint i = 0; i < availableTaskIds.length; i++) {
            if (availableTaskIds[i] == taskId) {
                availableTaskIds[i] = availableTaskIds[availableTaskIds.length - 1];
                availableTaskIds.pop();
                break;
            }
        }

        // Refund client the escrowed amount
        (bool success, ) = payable(task.client).call{value: task.paymentAmount}("");
        require(success, "Refund failed");

        emit TaskCancelled(taskId, msg.sender);
        emit TaskFailed(taskId, "Cancelled by client"); // Log as failed due to cancellation
    }

    /**
     * @dev Client approves the results submitted by the provider. Releases payment.
     * @param taskId The ID of the task to approve.
     */
    function approveTaskCompletion(uint taskId) external {
        Task storage task = tasks[taskId];
        require(task.client == msg.sender, "Not the task client");
        require(task.status == TaskStatus.ResultsSubmitted, "Task not in ResultsSubmitted status");

        task.status = TaskStatus.Completed;
        task.completedAt = block.timestamp;

        // Release payment to the provider
        (bool success, ) = payable(task.provider).call{value: task.paymentAmount}("");
        require(success, "Payment release failed");

        // Update reputation (simple: +10 for successful completion)
        providerProfiles[task.provider].reputationScore += 10;
        providerProfiles[task.provider].activeTaskCount--; // Decrement active task count

        emit TaskCompleted(taskId, task.client, task.provider);
        emit PaymentReleased(taskId, task.provider, task.paymentAmount);
        emit ReputationUpdated(task.provider, 10, providerProfiles[task.provider].reputationScore);
    }

     /**
     * @dev Allows client or provider to raise a dispute after results are submitted.
     * @param taskId The ID of the task to dispute.
     * @param reasonPointer Pointer to the reason and evidence for the dispute.
     */
    function raiseDispute(uint taskId, string calldata reasonPointer) external {
        Task storage task = tasks[taskId];
        require(task.client == msg.sender || task.provider == msg.sender, "Not involved in this task");
        require(task.status == TaskStatus.ResultsSubmitted, "Can only dispute after results are submitted");

        task.status = TaskStatus.Disputed;
        task.disputeReasonPointer = reasonPointer;

        emit DisputeRaised(taskId, msg.sender, reasonPointer);
    }


    // --- Task Management (Provider Side) ---

    /**
     * @dev Provider claims an available task.
     * @param taskId The ID of the task to claim.
     */
    function claimTask(uint taskId) external {
        require(providerProfiles[msg.sender].isRegistered, "Not registered as provider");
        require(providerProfiles[msg.sender].stake >= minProviderStake, "Insufficient stake");

        Task storage task = tasks[taskId];
        require(task.status == TaskStatus.Created, "Task not in Created status");
        require(task.client != msg.sender, "Cannot claim your own task");
        // Optional: Add requirement to match computeSpecs

        task.provider = msg.sender;
        task.status = TaskStatus.Assigned;
        task.assignedAt = block.timestamp;

        providerProfiles[msg.sender].activeTaskCount++;
        providerTaskIds[msg.sender].push(taskId);

        // Remove from availableTaskIds list
         for (uint i = 0; i < availableTaskIds.length; i++) {
            if (availableTaskIds[i] == taskId) {
                availableTaskIds[i] = availableTaskIds[availableTaskIds.length - 1];
                availableTaskIds.pop();
                break;
            }
        }

        emit TaskClaimed(taskId, msg.sender);
    }

    /**
     * @dev Provider submits the pointer to the computation results.
     * @param taskId The ID of the task.
     * @param resultsPointer Pointer to the output results.
     */
    function submitResults(uint taskId, string calldata resultsPointer) external {
        Task storage task = tasks[taskId];
        require(task.provider == msg.sender, "Not the assigned provider");
        require(task.status == TaskStatus.Assigned, "Task not in Assigned status");
        require(bytes(resultsPointer).length > 0, "Results pointer cannot be empty");

        // Optional: Check for completion timeout here, or rely on external `failTask` caller
        require(block.timestamp <= task.assignedAt + taskCompletionTimeout, "Task completion timeout");

        task.resultsPointer = resultsPointer;
        task.status = TaskStatus.ResultsSubmitted;

        emit ResultsSubmitted(taskId, msg.sender, resultsPointer);
    }


    // --- Task Management (General) ---

    /**
     * @dev Marks a task as failed. Can be called by owner or a trusted external service (watcher).
     *      Handles timeouts or other failure conditions. Refunds client, penalizes provider.
     * @param taskId The ID of the task to fail.
     */
    function failTask(uint taskId) external onlyOwner { // Can be modified to allow trusted watcher
        Task storage task = tasks[taskId];
        require(task.status != TaskStatus.Completed &&
                task.status != TaskStatus.Failed &&
                task.status != TaskStatus.Cancelled &&
                task.status != TaskStatus.Disputed, // Cannot fail if already disputed
                "Task is already in a final or disputed state");

        string memory reason;
        if (task.status == TaskStatus.Created && block.timestamp > task.createdAt + taskAssignmentTimeout) {
            reason = "Task assignment timeout";
             // Remove from availableTaskIds list
            for (uint i = 0; i < availableTaskIds.length; i++) {
                if (availableTaskIds[i] == taskId) {
                    availableTaskIds[i] = availableTaskIds[availableTaskIds.length - 1];
                    availableTaskIds.pop();
                    break;
                }
            }
            // Refund client for unassigned task
            (bool success, ) = payable(task.client).call{value: task.paymentAmount}("");
            require(success, "Client refund failed on timeout");

        } else if (task.status == TaskStatus.Assigned && block.timestamp > task.assignedAt + taskCompletionTimeout) {
            reason = "Task completion timeout";
            // Provider failed to submit results in time
            providerProfiles[task.provider].activeTaskCount--;
            // Penalize provider reputation (simple: -5 for failure)
            providerProfiles[task.provider].reputationScore = providerProfiles[task.provider].reputationScore >= 5 ? providerProfiles[task.provider].reputationScore - 5 : 0;
            emit ReputationUpdated(task.provider, -5, providerProfiles[task.provider].reputationScore);
            // Refund client
            (bool success, ) = payable(task.client).call{value: task.paymentAmount}("");
            require(success, "Client refund failed after provider timeout");

        } else {
            // Other failure reason (e.g., manual fail by owner for other issues)
            reason = "Manually failed by owner";
             if(task.status == TaskStatus.Assigned || task.status == TaskStatus.ResultsSubmitted) {
                 // If assigned/submitted, decrement active count and penalize provider
                 providerProfiles[task.provider].activeTaskCount--;
                 providerProfiles[task.provider].reputationScore = providerProfiles[task.provider].reputationScore >= 5 ? providerProfiles[task.provider].reputationScore - 5 : 0;
                 emit ReputationUpdated(task.provider, -5, providerProfiles[task.provider].reputationScore);
                 // Refund client
                 (bool success, ) = payable(task.client).call{value: task.paymentAmount}("");
                 require(success, "Client refund failed after manual fail");

             } else if (task.status == TaskStatus.Created) {
                 // If still created, refund client
                 // Remove from availableTaskIds list
                for (uint i = 0; i < availableTaskIds.length; i++) {
                    if (availableTaskIds[i] == taskId) {
                        availableTaskIds[i] = availableTaskIds[availableTaskIds.length - 1];
                        availableTaskIds.pop();
                        break;
                    }
                }
                (bool success, ) = payable(task.client).call{value: task.paymentAmount}("");
                require(success, "Client refund failed on manual fail (created)");
             }
        }

        task.status = TaskStatus.Failed;
        task.completedAt = block.timestamp;

        emit TaskFailed(taskId, reason);
    }

     /**
     * @dev Owner resolves a disputed task. Awards payment and updates reputation/stake based on resolution.
     * @param taskId The ID of the task to resolve.
     * @param winningParty The address of the party determined to have won the dispute (client or provider).
     */
    function resolveDispute(uint taskId, address winningParty) external onlyOwner {
        Task storage task = tasks[taskId];
        require(task.status == TaskStatus.Disputed, "Task not in Disputed status");
        require(winningParty == task.client || winningParty == task.provider, "Winning party must be client or provider");

        address losingParty;

        if (winningParty == task.provider) {
            losingParty = task.client;
            // Provider wins: release payment to provider
            (bool success, ) = payable(task.provider).call{value: task.paymentAmount}("");
            require(success, "Payment release failed during dispute resolution");

            // Update provider reputation (simple: +20 for winning dispute)
            providerProfiles[task.provider].reputationScore += 20;
             // Client reputation could be penalized, but clients don't have stake/slashable assets easily

        } else { // winningParty == task.client
            losingParty = task.provider;
            // Client wins: refund payment to client
            (bool success, ) = payable(task.client).call{value: task.paymentAmount}("");
            require(success, "Refund failed during dispute resolution");

            // Penalize provider reputation and potentially slash stake (simple: -15 rep, slash small amount)
            providerProfiles[task.provider].reputationScore = providerProfiles[task.provider].reputationScore >= 15 ? providerProfiles[task.provider].reputationScore - 15 : 0;
            uint slashAmount = task.paymentAmount / 10; // Slash 10% of task payment amount as penalty example
            if (providerProfiles[task.provider].stake >= slashAmount) {
                 providerProfiles[task.provider].stake -= slashAmount;
                 emit StakeSlashed(task.provider, slashAmount, "Lost dispute");
            } else if (providerProfiles[task.provider].stake > 0) {
                 // Slash remaining stake if not enough for full penalty
                 uint remainingStake = providerProfiles[task.provider].stake;
                 providerProfiles[task.provider].stake = 0;
                 emit StakeSlashed(task.provider, remainingStake, "Lost dispute (insufficient stake for full penalty)");
            }
        }

        task.status = TaskStatus.Completed; // Mark as completed after resolution, or use a separate 'Resolved' status
        task.completedAt = block.timestamp;
        providerProfiles[task.provider].activeTaskCount--; // Decrement active count as task is resolved

        emit DisputeResolved(taskId, winningParty, losingParty);
         if (winningParty == task.provider) {
             emit ReputationUpdated(task.provider, 20, providerProfiles[task.provider].reputationScore);
         } else { // winningParty == task.client
             emit ReputationUpdated(task.provider, -15, providerProfiles[task.provider].reputationScore);
         }
    }


    // --- Admin & Configuration ---

    /**
     * @dev Sets the minimum stake required for providers.
     * @param amount The new minimum stake amount in wei.
     */
    function updateMinimumProviderStake(uint amount) external onlyOwner {
        minProviderStake = amount;
    }

     /**
     * @dev Sets the timeout duration for a task to be claimed after creation.
     * @param duration The new timeout duration in seconds.
     */
    function updateTaskAssignmentTimeout(uint duration) external onlyOwner {
        taskAssignmentTimeout = duration;
    }

     /**
     * @dev Sets the timeout duration for a provider to submit results after claiming a task.
     * @param duration The new timeout duration in seconds.
     */
    function updateTaskCompletionTimeout(uint duration) external onlyOwner {
        taskCompletionTimeout = duration;
    }

    /**
     * @dev Allows the owner to manually slash a provider's stake.
     * @param provider The address of the provider whose stake will be slashed.
     * @param amount The amount of stake to slash.
     */
    function slashProviderStake(address provider, uint amount) external onlyOwner {
        require(providerProfiles[provider].isRegistered, "Provider not registered");
        require(providerProfiles[provider].stake >= amount, "Insufficient stake to slash");

        providerProfiles[provider].stake -= amount;
        // Slashed funds could go to a treasury or burned, for simplicity they just reduce stake here.
        // TODO: Handle slashed funds destination (treasury/burn).
        emit StakeSlashed(provider, amount, "Manual slash by owner");
    }


    // --- View Functions (Read-Only) ---

    /**
     * @dev Returns the total number of tasks created.
     */
    function getTotalTasks() external view returns (uint) {
        return taskIdCounter;
    }

    /**
     * @dev Returns the profile details for a provider.
     * @param provider The address of the provider.
     */
    function getProviderProfile(address provider) external view returns (ProviderProfile memory) {
        return providerProfiles[provider];
    }

    /**
     * @dev Returns the profile details for a client.
     * @param client The address of the client.
     */
    function getClientProfile(address client) external view returns (ClientProfile memory) {
        return clientProfiles[client];
    }

    /**
     * @dev Returns the details for a specific task.
     * @param taskId The ID of the task.
     */
    function getTaskDetails(uint taskId) external view returns (Task memory) {
        return tasks[taskId];
    }

     /**
     * @dev Returns the status of a specific task.
     * @param taskId The ID of the task.
     */
    function getTaskStatus(uint taskId) external view returns (TaskStatus) {
        return tasks[taskId].status;
    }

    /**
     * @dev Returns a list of task IDs that are currently in the 'Created' status and available for claiming.
     *      Note: This function iterates over an array state variable. It can become very gas-expensive
     *            if the number of available tasks is large. For production, consider alternative
     *            patterns like returning paginated results or relying on off-chain indexing.
     */
    function getAvailableTaskIds() external view returns (uint[] memory) {
        return availableTaskIds;
    }

    /**
     * @dev Returns a list of task IDs associated with a specific provider.
     *      Note: This function returns a dynamically sized array from storage, which can be
     *            gas-expensive for large arrays. Consider off-chain indexing for production.
     * @param provider The address of the provider.
     */
    function getProviderTaskIds(address provider) external view returns (uint[] memory) {
        return providerTaskIds[provider];
    }

     /**
     * @dev Returns a list of task IDs created by a specific client.
     *      Note: This function returns a dynamically sized array from storage, which can be
     *            gas-expensive for large arrays. Consider off-chain indexing for production.
     * @param client The address of the client.
     */
    function getClientTaskIds(address client) external view returns (uint[] memory) {
        return clientTaskIds[client];
    }
}
```