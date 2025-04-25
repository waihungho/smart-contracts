Okay, let's design a smart contract for a Decentralized AI Compute Marketplace. This involves requesters submitting AI computation jobs, providers offering compute resources and performing the jobs off-chain, and the contract managing job states, payments, and resource registration.

This concept is advanced as it bridges on-chain coordination with off-chain work, requires managing different roles and complex job lifecycles, and can incorporate ideas like staking for reliability and abstract resource units.

**Smart Contract Concept:** Decentralized AI Compute Marketplace

**Description:** This contract facilitates a marketplace where users (Requesters) can submit requests for AI computation tasks (like training small models, running inference, data processing for AI), and other users (Providers) can offer their computing resources (CPU, GPU, RAM) to fulfill these requests. The contract manages the job lifecycle, payment escrow, provider registration, and basic resource representation. The actual computation happens off-chain, but the contract coordinates the process and handles payment upon successful completion/verification.

**Key Features:**
*   Provider Registration and Resource Listing.
*   Provider Staking (Collateral for reliability).
*   Job Creation with specific resource requirements and payment.
*   Job Assignment to Providers.
*   Result Submission (via hash or reference).
*   Job Completion/Verification.
*   Payment Release to Providers.
*   Slashing mechanism for non-performing Providers.
*   Platform Fee Collection.
*   Support for different AI Models (represented by IDs).

---

**Outline and Function Summary**

**Structs:**

1.  `ComputeResource`: Represents the specifications of a provider's computing power (e.g., CPU cores, GPU count/type, RAM, storage).
2.  `ComputeProvider`: Stores provider details, registered resources, stake amount, and availability status.
3.  `ComputeJob`: Stores job details, requester, assigned provider, state, required resources, payment, result hash, etc.
4.  `SupportedAIModel`: Stores details about a supported AI model (ID, name, basic specs/requirements).

**Enums:**

1.  `JobState`: Defines the current status of a compute job (e.g., Pending, Assigned, Computing, ResultsSubmitted, Verified, Failed, Cancelled).

**Events:**

1.  `ProviderRegistered`: Emitted when a new provider registers.
2.  `ProviderUpdated`: Emitted when provider resources or availability are updated.
3.  `ProviderStaked`: Emitted when a provider stakes collateral.
4.  `ProviderStakeWithdrawn`: Emitted when a provider withdraws stake.
5.  `JobCreated`: Emitted when a new compute job is submitted.
6.  `JobAccepted`: Emitted when a provider accepts a job.
7.  `JobResultSubmitted`: Emitted when a provider submits results.
8.  `JobVerified`: Emitted when a job is verified as completed.
9.  `JobCancelled`: Emitted when a job is cancelled by the requester.
10. `JobFailed`: Emitted when a job is marked as failed.
11. `ProviderSlashed`: Emitted when a provider's stake is slashed.
12. `PlatformFeesWithdrawn`: Emitted when owner withdraws fees.
13. `AIModelAdded`: Emitted when a new supported AI model is added.
14. `AIModelRemoved`: Emitted when a supported AI model is removed.

**State Variables:**

*   `owner`: The contract owner (for administrative functions).
*   `providerCount`: Counter for unique provider IDs.
*   `providers`: Mapping from provider address to `ComputeProvider` struct.
*   `jobCounter`: Counter for unique job IDs.
*   `jobs`: Mapping from job ID to `ComputeJob` struct.
*   `supportedAIModels`: Mapping from model ID to `SupportedAIModel` struct.
*   `supportedModelIds`: Array of supported model IDs.
*   `platformFeePercentage`: Percentage of job payment collected as fee.
*   `minProviderStake`: Minimum required stake for providers.
*   `platformBalance`: Accumulated platform fees.

**Functions (25 total):**

1.  `constructor()`: Sets the contract owner and initial parameters.
2.  `registerProvider(ComputeResource calldata _resources)`: Registers the caller as a compute provider with specified resources. Requires staking minimum collateral.
3.  `updateProviderResources(ComputeResource calldata _resources)`: Updates the resource details for an existing provider.
4.  `stakeProviderCollateral()`: Allows a registered provider to add more ETH to their stake.
5.  `withdrawProviderCollateral(uint256 _amount)`: Allows a provider to withdraw stake. Requires no active jobs and stake remaining above minimum.
6.  `setProviderAvailability(bool _isAvailable)`: Sets a provider's availability status for accepting new jobs.
7.  `getProviderDetails(address _providerAddress)`: Retrieves details of a registered provider.
8.  `getProviderJobs(address _providerAddress)`: Retrieves a list of job IDs assigned to a provider.
9.  `createComputeJob(uint256 _modelId, ComputeResource calldata _requiredResources, bytes32 _inputDataHash, uint256 _maxPayment)`: Creates a new compute job. Requires depositing `_maxPayment` ETH.
10. `cancelComputeJob(uint256 _jobId)`: Allows the job requester to cancel a job if it's still in the `Pending` state. Refunds the payment.
11. `listAvailableJobs()`: Returns a list of job IDs that are currently in the `Pending` state.
12. `acceptComputeJob(uint256 _jobId)`: Allows an available provider to accept a `Pending` job that matches their resources. Sets job state to `Assigned`.
13. `submitJobResult(uint256 _jobId, bytes32 _resultHash)`: Allows the assigned provider to submit the hash of the computation result. Sets job state to `ResultsSubmitted`.
14. `verifyJobCompletion(uint256 _jobId)`: (Simplified: done by requester or potentially a trusted party/oracle) Marks the job as verified, transfers payment to the provider (minus fee), and updates job state to `Verified`.
15. `reportJobFailure(uint256 _jobId, string calldata _reason)`: Allows requester or provider to report a job failure. Sets state to `Failed` and potentially triggers slashing (simplified: slashing done separately).
16. `claimJobResult(uint256 _jobId)`: Allows the requester of a `Verified` job to acknowledge claiming the off-chain result (no state change, purely for tracking).
17. `getJobDetails(uint256 _jobId)`: Retrieves details of a specific compute job.
18. `getRequesterJobs(address _requesterAddress)`: Retrieves a list of job IDs created by a specific requester.
19. `addSupportedAIModel(uint256 _modelId, string calldata _name, ComputeResource calldata _baseRequirements)`: (Owner) Adds a new AI model type that the marketplace supports.
20. `removeSupportedAIModel(uint256 _modelId)`: (Owner) Removes a supported AI model type.
21. `getPlatformStats()`: Returns basic statistics about the platform (total providers, total jobs).
22. `setPlatformFeePercentage(uint256 _percentage)`: (Owner) Sets the platform fee percentage.
23. `setMinProviderStake(uint256 _amount)`: (Owner) Sets the minimum required stake for providers.
24. `slashProvider(address _providerAddress, uint256 _amount, uint256 _jobId)`: (Owner/Admin or via dispute system) Slashes a provider's stake, potentially refunding the job payment to the requester for the specified job.
25. `withdrawPlatformFees(uint256 _amount)`: (Owner) Withdraws accumulated platform fees.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title DecentralizedAIAIComputeMarketplace
 * @dev A smart contract for coordinating decentralized AI computation jobs.
 * Requesters submit jobs, Providers offer compute resources and perform work off-chain,
 * and the contract manages payments, state, and provider registration.
 */
contract DecentralizedAIAIComputeMarketplace {

    // --- Structs ---

    /**
     * @dev Represents the specifications of a provider's computing power.
     * Abstracted for simplicity; could be more detailed (e.g., specific GPU models).
     */
    struct ComputeResource {
        uint256 cpuCores;
        uint256 gpuCount;
        uint256 ramGB;
        uint256 storageGB;
        // Could add specific types, e.g., string gpuType;
    }

    /**
     * @dev Represents a registered compute provider.
     * Stores their resources, stake, and job status.
     */
    struct ComputeProvider {
        address providerAddress;
        ComputeResource resources;
        uint256 stake; // ETH staked as collateral
        bool isAvailable; // Can accept new jobs
        bool isRegistered; // True if the address is a registered provider
        uint256[] acceptedJobIds; // List of jobs accepted by this provider
    }

    /**
     * @dev Represents a compute job request.
     * Created by a requester, assigned to a provider, tracked through states.
     */
    struct ComputeJob {
        uint256 jobId;
        address requester;
        address provider; // Assigned provider address (0x0 initially)
        uint256 modelId; // ID referencing a supported AI model
        ComputeResource requiredResources; // Resources requested for the job
        uint256 maxPayment; // Maximum payment offered for the job
        bytes32 inputDataHash; // Hash or reference to the off-chain input data
        bytes32 resultHash; // Hash or reference to the off-chain result data
        JobState state; // Current state of the job
        uint64 creationTimestamp; // Timestamp when the job was created
        uint64 assignmentTimestamp; // Timestamp when the job was assigned
        uint64 resultSubmissionTimestamp; // Timestamp when result was submitted
        uint64 verificationTimestamp; // Timestamp when job was verified
        uint256 paymentAmount; // Actual payment amount determined (could be less than maxPayment)
        bool isClaimedByRequester; // Whether the requester has acknowledged claiming the result
    }

    /**
     * @dev Represents a supported AI model type on the marketplace.
     */
    struct SupportedAIModel {
        uint256 modelId;
        string name;
        ComputeResource baseRequirements; // Base resources recommended/required for this model type
        bool isSupported; // True if the model ID is currently supported
    }

    // --- Enums ---

    /**
     * @dev States a compute job can be in.
     * Pending: Job created, waiting for a provider.
     * Assigned: Job accepted by a provider.
     * Computing: Provider is working on the job (internal/off-chain state, reflected by Assignment).
     * ResultsSubmitted: Provider submitted results.
     * Verified: Results verified (off-chain or via oracle), payment pending.
     * Paid: Payment transferred to provider. (Let's combine Verified and Paid for simplicity here)
     * Failed: Job failed, maybe due to provider issue or invalid input.
     * Cancelled: Job cancelled by requester before assignment.
     */
    enum JobState {
        Pending,
        Assigned, // Computing implicitly happens off-chain after assignment
        ResultsSubmitted,
        Verified, // Payment happens upon verification
        Failed,
        Cancelled
    }

    // --- Events ---

    event ProviderRegistered(address indexed provider, uint256 timestamp);
    event ProviderUpdated(address indexed provider, uint256 timestamp);
    event ProviderStaked(address indexed provider, uint256 amount, uint256 totalStake, uint256 timestamp);
    event ProviderStakeWithdrawn(address indexed provider, uint256 amount, uint256 totalStake, uint256 timestamp);
    event JobCreated(uint256 indexed jobId, address indexed requester, uint256 modelId, uint256 maxPayment, uint256 timestamp);
    event JobAccepted(uint256 indexed jobId, address indexed provider, uint256 timestamp);
    event JobResultSubmitted(uint256 indexed jobId, address indexed provider, bytes32 resultHash, uint256 timestamp);
    event JobVerified(uint256 indexed jobId, address indexed provider, uint256 paymentAmount, uint256 timestamp);
    event JobCancelled(uint256 indexed jobId, address indexed requester, uint256 refundAmount, uint256 timestamp);
    event JobFailed(uint256 indexed jobId, address indexed participant, string reason, uint256 timestamp);
    event ProviderSlashed(address indexed provider, uint256 indexed jobId, uint256 amount, uint256 remainingStake, uint256 timestamp);
    event PlatformFeesWithdrawn(address indexed owner, uint256 amount, uint256 timestamp);
    event AIModelAdded(uint256 indexed modelId, string name, uint256 timestamp);
    event AIModelRemoved(uint256 indexed modelId, uint256 timestamp);

    // --- State Variables ---

    address public owner; // Contract owner for administrative tasks

    uint256 private providerCounter = 0; // Simple counter, address is the key
    mapping(address => ComputeProvider) public providers;

    uint256 private jobCounter = 0; // Counter for unique job IDs
    mapping(uint256 => ComputeJob) public jobs;

    mapping(uint256 => SupportedAIModel) public supportedAIModels;
    uint256[] public supportedModelIds; // Keep track of IDs for listing

    uint256 public platformFeePercentage; // e.g., 5 for 5%
    uint256 public minProviderStake; // Minimum ETH required for provider stake

    uint256 public platformBalance; // Accumulated fees in wei

    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier onlyRegisteredProvider() {
        require(providers[msg.sender].isRegistered, "Caller is not a registered provider");
        _;
    }

    modifier onlyJobRequester(uint256 _jobId) {
        require(jobs[_jobId].requester == msg.sender, "Caller is not the job requester");
        _;
    }

    modifier onlyJobProvider(uint256 _jobId) {
        require(jobs[_jobId].provider == msg.sender, "Caller is not the job provider");
        _;
    }

    // --- Constructor ---

    constructor(uint256 _initialFeePercentage, uint256 _initialMinStake) {
        owner = msg.sender;
        platformFeePercentage = _initialFeePercentage; // Max 100
        minProviderStake = _initialMinStake; // In wei
    }

    // --- Provider Functions (7) ---

    /**
     * @dev Registers the caller as a compute provider.
     * Requires sending minimum stake with the transaction.
     * @param _resources Compute resources offered by the provider.
     */
    function registerProvider(ComputeResource calldata _resources) external payable {
        require(!providers[msg.sender].isRegistered, "Provider is already registered");
        require(msg.value >= minProviderStake, "Insufficient stake");

        providers[msg.sender] = ComputeProvider({
            providerAddress: msg.sender,
            resources: _resources,
            stake: msg.value,
            isAvailable: true,
            isRegistered: true,
            acceptedJobIds: new uint256[](0)
        });
        providerCounter++; // Increment counter (for stats, address is key)

        emit ProviderRegistered(msg.sender, block.timestamp);
        emit ProviderStaked(msg.sender, msg.value, providers[msg.sender].stake, block.timestamp);
    }

    /**
     * @dev Updates the resource details for the caller (a registered provider).
     * @param _resources New compute resources offered by the provider.
     */
    function updateProviderResources(ComputeResource calldata _resources) external onlyRegisteredProvider {
        providers[msg.sender].resources = _resources;
        emit ProviderUpdated(msg.sender, block.timestamp);
    }

    /**
     * @dev Allows a registered provider to add more ETH to their stake.
     */
    function stakeProviderCollateral() external payable onlyRegisteredProvider {
        require(msg.value > 0, "Must send ETH to stake");
        providers[msg.sender].stake += msg.value;
        emit ProviderStaked(msg.sender, msg.value, providers[msg.sender].stake, block.timestamp);
    }

    /**
     * @dev Allows a registered provider to withdraw part of their stake.
     * Cannot withdraw below minimum stake if there are active jobs (simplified check).
     * @param _amount Amount of ETH to withdraw (in wei).
     */
    function withdrawProviderCollateral(uint256 _amount) external onlyRegisteredProvider {
        ComputeProvider storage provider = providers[msg.sender];
        require(_amount > 0, "Must withdraw a positive amount");
        require(provider.stake >= _amount, "Insufficient stake");

        // Simple check: prevent withdrawal if stake goes below minimum AND provider has active jobs
        // A more robust system would check specific job states (Assigned, ResultsSubmitted)
        bool hasActiveJobs = provider.acceptedJobIds.length > 0; // This is a very basic check
        if (hasActiveJobs) {
             require(provider.stake - _amount >= minProviderStake, "Cannot withdraw below minimum stake while having active jobs");
        } else {
             require(provider.stake - _amount >= 0, "Cannot withdraw more than available stake"); // Can withdraw everything if no active jobs
        }


        provider.stake -= _amount;

        // Use low-level call for robustness against reentrancy patterns
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "ETH withdrawal failed");

        emit ProviderStakeWithdrawn(msg.sender, _amount, provider.stake, block.timestamp);
    }

    /**
     * @dev Sets the availability status of a registered provider.
     * Only available providers can accept new jobs.
     * @param _isAvailable New availability status.
     */
    function setProviderAvailability(bool _isAvailable) external onlyRegisteredProvider {
        providers[msg.sender].isAvailable = _isAvailable;
        emit ProviderUpdated(msg.sender, block.timestamp); // Reuse event for update notification
    }

    /**
     * @dev Retrieves details of a specific provider.
     * @param _providerAddress The address of the provider.
     * @return ComputeProvider struct.
     */
    function getProviderDetails(address _providerAddress) external view returns (ComputeProvider memory) {
        require(providers[_providerAddress].isRegistered, "Provider not registered");
        return providers[_providerAddress];
    }

     /**
     * @dev Retrieves the list of job IDs accepted by a specific provider.
     * @param _providerAddress The address of the provider.
     * @return Array of job IDs.
     */
    function getProviderJobs(address _providerAddress) external view returns (uint256[] memory) {
        require(providers[_providerAddress].isRegistered, "Provider not registered");
        return providers[_providerAddress].acceptedJobIds;
    }

    // --- Job Functions (Requester Side) (6) ---

    /**
     * @dev Creates a new compute job request.
     * Requires sending the maximum payment amount with the transaction.
     * @param _modelId The ID of the supported AI model needed.
     * @param _requiredResources Minimum resources required for the job.
     * @param _inputDataHash Hash or reference to the off-chain input data (e.g., IPFS hash).
     * @param _maxPayment Maximum ETH payment offered for the job (sent with tx).
     */
    function createComputeJob(
        uint256 _modelId,
        ComputeResource calldata _requiredResources,
        bytes32 _inputDataHash,
        uint256 _maxPayment
    ) external payable {
        require(msg.value == _maxPayment, "Sent amount must match maxPayment");
        require(supportedAIModels[_modelId].isSupported, "Unsupported AI model ID");
        // Basic resource check against supported model base requirements could be added

        jobCounter++;
        uint256 jobId = jobCounter;

        jobs[jobId] = ComputeJob({
            jobId: jobId,
            requester: msg.sender,
            provider: address(0), // No provider assigned yet
            modelId: _modelId,
            requiredResources: _requiredResources,
            maxPayment: _maxPayment,
            inputDataHash: _inputDataHash,
            resultHash: bytes32(0), // No result yet
            state: JobState.Pending,
            creationTimestamp: uint64(block.timestamp),
            assignmentTimestamp: 0,
            resultSubmissionTimestamp: 0,
            verificationTimestamp: 0,
            paymentAmount: 0, // Determined upon verification
            isClaimedByRequester: false
        });

        emit JobCreated(jobId, msg.sender, _modelId, _maxPayment, block.timestamp);
    }

    /**
     * @dev Allows the job requester to cancel a job.
     * Only possible if the job is in the Pending state. Refunds the payment.
     * @param _jobId The ID of the job to cancel.
     */
    function cancelComputeJob(uint256 _jobId) external onlyJobRequester(_jobId) {
        ComputeJob storage job = jobs[_jobId];
        require(job.state == JobState.Pending, "Job is not in Pending state");

        job.state = JobState.Cancelled;

        // Refund payment
        (bool success, ) = payable(job.requester).call{value: job.maxPayment}("");
        require(success, "Payment refund failed");

        emit JobCancelled(_jobId, msg.sender, job.maxPayment, block.timestamp);
    }

    /**
     * @dev Allows the requester of a Verified job to acknowledge claiming the off-chain result.
     * This is just a state flag on-chain, doesn't transfer data.
     * @param _jobId The ID of the job.
     */
    function claimJobResult(uint256 _jobId) external onlyJobRequester(_jobId) {
        ComputeJob storage job = jobs[_jobId];
        require(job.state == JobState.Verified, "Job is not in Verified state");
        require(!job.isClaimedByRequester, "Result already claimed");

        job.isClaimedByRequester = true;
        // Event for tracking might be useful
        // emit JobResultClaimed(_jobId, msg.sender, block.timestamp);
    }

    /**
     * @dev Retrieves details of a specific compute job.
     * @param _jobId The ID of the job.
     * @return ComputeJob struct.
     */
    function getJobDetails(uint256 _jobId) external view returns (ComputeJob memory) {
        require(_jobId > 0 && _jobId <= jobCounter, "Invalid job ID");
        return jobs[_jobId];
    }

     /**
     * @dev Retrieves the list of job IDs created by a specific requester.
     * Note: This function iterates through all jobs. For a large number of jobs,
     * a more efficient pattern (like tracking job IDs per requester mapping)
     * would be needed off-chain or within the contract (more storage cost).
     * @param _requesterAddress The address of the requester.
     * @return Array of job IDs.
     */
    function getRequesterJobs(address _requesterAddress) external view returns (uint256[] memory) {
        uint256[] memory requesterJobIds = new uint256[](jobCounter);
        uint256 count = 0;
        for (uint256 i = 1; i <= jobCounter; i++) {
            if (jobs[i].requester == _requesterAddress) {
                requesterJobIds[count] = i;
                count++;
            }
        }
        // Resize the array to the actual count
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = requesterJobIds[i];
        }
        return result;
    }

     /**
     * @dev Returns a list of job IDs that are currently in the Pending state.
     * Iterates through all jobs. See note on getRequesterJobs regarding efficiency.
     * @return Array of pending job IDs.
     */
    function listAvailableJobs() external view returns (uint256[] memory) {
         uint256[] memory pendingJobIds = new uint256[](jobCounter);
        uint256 count = 0;
        for (uint256 i = 1; i <= jobCounter; i++) {
            if (jobs[i].state == JobState.Pending) {
                 // Add checks for provider resource compatibility here if needed
                pendingJobIds[count] = i;
                count++;
            }
        }
        // Resize the array
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = pendingJobIds[i];
        }
        return result;
    }


    // --- Job Functions (Provider Side) (2) ---

    /**
     * @dev Allows an available provider to accept a pending job.
     * Checks provider availability and potentially resource compatibility (simplified check needed).
     * Sets the job state to Assigned.
     * @param _jobId The ID of the job to accept.
     */
    function acceptComputeJob(uint256 _jobId) external onlyRegisteredProvider {
        ComputeJob storage job = jobs[_jobId];
        ComputeProvider storage provider = providers[msg.sender];

        require(job.state == JobState.Pending, "Job is not in Pending state");
        require(provider.isAvailable, "Provider is not available");
        // TODO: Add check here to ensure provider resources meet job requirements

        job.provider = msg.sender;
        job.state = JobState.Assigned;
        job.assignmentTimestamp = uint64(block.timestamp);

        provider.acceptedJobIds.push(_jobId); // Add job ID to provider's list

        emit JobAccepted(_jobId, msg.sender, block.timestamp);
    }

    /**
     * @dev Allows the assigned provider to submit the hash of the computation result.
     * Sets the job state to ResultsSubmitted. The result itself is off-chain.
     * @param _jobId The ID of the job.
     * @param _resultHash Hash or reference to the off-chain result data (e.g., IPFS hash).
     */
    function submitJobResult(uint256 _jobId, bytes32 _resultHash) external onlyJobProvider(_jobId) {
        ComputeJob storage job = jobs[_jobId];
        require(job.state == JobState.Assigned, "Job is not in Assigned state");
        require(_resultHash != bytes32(0), "Result hash cannot be zero");

        job.resultHash = _resultHash;
        job.state = JobState.ResultsSubmitted;
        job.resultSubmissionTimestamp = uint64(block.timestamp);

        emit JobResultSubmitted(_jobId, msg.sender, _resultHash, block.timestamp);
    }

    // --- Completion / Verification Functions (2) ---

    /**
     * @dev Marks a job as verified and transfers payment to the provider (minus fee).
     * This function would ideally be triggered by an oracle, a validation network,
     * or the requester confirming off-chain result validity.
     * @param _jobId The ID of the job to verify.
     */
    function verifyJobCompletion(uint256 _jobId) external {
        ComputeJob storage job = jobs[_jobId];
        require(job.state == JobState.ResultsSubmitted || job.state == JobState.Assigned,
                "Job is not in ResultsSubmitted or Assigned state");
        // Simple verification: In a real system, this would require external verification logic.
        // For this example, let's allow the requester OR the owner to verify.
        require(msg.sender == job.requester || msg.sender == owner, "Only requester or owner can verify");

        job.state = JobState.Verified;
        job.verificationTimestamp = uint64(block.timestamp);

        // Calculate payment and fees
        uint256 payment = job.maxPayment; // Simplified: provider always gets maxPayment if verified
        uint256 feeAmount = (payment * platformFeePercentage) / 100;
        uint256 providerPayment = payment - feeAmount;

        job.paymentAmount = providerPayment;
        platformBalance += feeAmount;

        // Transfer payment to provider
        (bool success, ) = payable(job.provider).call{value: providerPayment}("");
        // If transfer fails, ideally the state should revert or allow retry.
        // For simplicity, we just require success here.
        require(success, "Payment transfer to provider failed");

        emit JobVerified(_jobId, job.provider, providerPayment, block.timestamp);
    }

     /**
     * @dev Allows a participant (requester or provider) to report a job failure.
     * Sets job state to Failed. Could trigger slashing mechanism.
     * @param _jobId The ID of the job.
     * @param _reason A string explaining the reason for failure.
     */
    function reportJobFailure(uint256 _jobId, string calldata _reason) external {
        ComputeJob storage job = jobs[_jobId];
        require(msg.sender == job.requester || msg.sender == job.provider, "Only job participants can report failure");
        require(job.state > JobState.Pending && job.state < JobState.Verified, "Job is in invalid state to report failure"); // Cannot report failure if Pending, Verified, or Cancelled

        job.state = JobState.Failed;
        // No automatic slashing here, needs separate `slashProvider` call or dispute system

        emit JobFailed(_jobId, msg.sender, _reason, block.timestamp);
    }

    // --- Platform / Admin Functions (6) ---

    /**
     * @dev (Owner) Adds a new supported AI model type.
     * @param _modelId A unique ID for the model.
     * @param _name The name of the model.
     * @param _baseRequirements Base compute resources recommended for this model.
     */
    function addSupportedAIModel(uint256 _modelId, string calldata _name, ComputeResource calldata _baseRequirements) external onlyOwner {
        require(!supportedAIModels[_modelId].isSupported, "Model ID already supported");
        supportedAIModels[_modelId] = SupportedAIModel({
            modelId: _modelId,
            name: _name,
            baseRequirements: _baseRequirements,
            isSupported: true
        });
        supportedModelIds.push(_modelId); // Add to list for enumeration
        emit AIModelAdded(_modelId, _name, block.timestamp);
    }

    /**
     * @dev (Owner) Removes a supported AI model type.
     * Does not affect existing jobs using this model ID.
     * @param _modelId The ID of the model to remove.
     */
    function removeSupportedAIModel(uint256 _modelId) external onlyOwner {
        require(supportedAIModels[_modelId].isSupported, "Model ID is not supported");
        supportedAIModels[_modelId].isSupported = false;

        // Optional: Remove from supportedModelIds array (inefficient for large arrays)
        for (uint256 i = 0; i < supportedModelIds.length; i++) {
            if (supportedModelIds[i] == _modelId) {
                // Swap with last element and pop
                supportedModelIds[i] = supportedModelIds[supportedModelIds.length - 1];
                supportedModelIds.pop();
                break; // Found and removed
            }
        }

        emit AIModelRemoved(_modelId, block.timestamp);
    }

    /**
     * @dev (Owner) Sets the platform fee percentage.
     * @param _percentage New fee percentage (0-100).
     */
    function setPlatformFeePercentage(uint256 _percentage) external onlyOwner {
        require(_percentage <= 100, "Fee percentage cannot exceed 100");
        platformFeePercentage = _percentage;
    }

    /**
     * @dev (Owner) Sets the minimum required stake for providers.
     * @param _amount New minimum stake amount (in wei).
     */
    function setMinProviderStake(uint256 _amount) external onlyOwner {
        minProviderStake = _amount;
    }

    /**
     * @dev (Owner or potentially dispute system) Slashes a provider's stake.
     * Can be called due to failure, fraud, etc. (Requires off-chain validation or dispute).
     * The slashed amount can be transferred (e.g., back to requester for a failed job).
     * @param _providerAddress The address of the provider to slash.
     * @param _amount The amount of stake to slash (in wei).
     * @param _jobId The job ID related to the slashing (0 if not specific to a job).
     */
    function slashProvider(address _providerAddress, uint256 _amount, uint256 _jobId) external onlyOwner {
        ComputeProvider storage provider = providers[_providerAddress];
        require(provider.isRegistered, "Provider not registered");
        require(_amount > 0 && provider.stake >= _amount, "Invalid slash amount");

        provider.stake -= _amount;

        // Decide where the slashed amount goes. Example: send back to requester if related to a failed job.
        if (_jobId != 0 && jobs[_jobId].requester != address(0)) {
             // Note: This assumes the slashed amount is tied to a specific job failure refund.
             // A more complex system might distribute slashing rewards or burn tokens.
             (bool success, ) = payable(jobs[_jobId].requester).call{value: _amount}("");
             // Log failure but don't revert if refund fails, slashing still happened.
             if (!success) {
                 // Log this failure off-chain
             }
        } else {
            // If not tied to a job, potentially send to owner, burn, or other mechanism.
            // For simplicity, let's just leave it in the contract balance (effectively burned if not owner withdrawal).
            // Or transfer to owner: payable(owner).transfer(_amount);
        }


        emit ProviderSlashed(_providerAddress, _jobId, _amount, provider.stake, block.timestamp);
    }


    /**
     * @dev (Owner) Withdraws accumulated platform fees.
     * @param _amount Amount of fees to withdraw (in wei).
     */
    function withdrawPlatformFees(uint256 _amount) external onlyOwner {
        require(_amount > 0, "Must withdraw a positive amount");
        require(platformBalance >= _amount, "Insufficient platform balance");

        platformBalance -= _amount;

        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "Fee withdrawal failed");

        emit PlatformFeesWithdrawn(msg.sender, _amount, block.timestamp);
    }

    // --- Utility Functions (2) ---

    /**
     * @dev Returns basic statistics about the platform.
     * @return totalProviders Total number of registered providers.
     * @return totalJobs Total number of jobs created.
     * @return currentPlatformBalance Current balance of accumulated fees.
     */
    function getPlatformStats() external view returns (uint256 totalProviders, uint256 totalJobs, uint256 currentPlatformBalance) {
        // Note: providerCounter is not the exact *active* provider count if some addresses registered multiple times
        // or if registration wasn't strictly 1:1 counter. Using address mapping length is not possible in Solidity view.
        // A dedicated counter incremented *only* on new unique registrations would be better.
        // For simplicity, let's return the job counter and balance. providerCounter is less reliable without further logic.
        return (providerCounter, jobCounter, platformBalance); // Use providerCounter for approximation
    }

     /**
     * @dev Retrieves the list of supported AI model IDs.
     * @return Array of supported model IDs.
     */
    function getSupportedModelIds() external view returns (uint256[] memory) {
        return supportedModelIds;
    }
}
```