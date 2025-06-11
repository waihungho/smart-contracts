Okay, let's design a smart contract for a **Decentralized AI Compute Marketplace**. This concept involves users requesting AI tasks (like model training, inference, data processing) to be performed by other users who offer their compute power. It includes concepts like escrow, provider staking, job state management, reputation hints, and dispute placeholders.

This isn't a simple token or NFT contract. It involves a complex workflow and state machine.

Here's the outline and summary followed by the Solidity code.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title DecentralizedAIComputeMarketplace
 * @dev A smart contract for a decentralized marketplace connecting users who need AI computation
 *      (Requesters) with users who can provide it (Providers).
 *      It manages job creation, provider application/selection, payment escrow, result submission,
 *      verification, and basic dispute flow.
 *      Computation itself happens OFF-CHAIN, while the contract manages the coordination,
 *      payments, and state transitions ON-CHAIN.
 */

/**
 * @dev Outline:
 * 1. State Variables: Store contract parameters, provider info, job info, balances.
 * 2. Enums: Define job states.
 * 3. Structs: Define data structures for Providers and Jobs.
 * 4. Events: Signal key state changes.
 * 5. Modifiers: Restrict function access based on role or state.
 * 6. Admin Functions (Ownable): Set parameters, withdraw fees, pause/unpause, resolve disputes.
 * 7. Provider Management Functions: Register, update capabilities, stake, unstake, withdraw stake.
 * 8. Job Creation & Management (Requester): Create, update (before selection), cancel (before selection),
 *    select provider, rescind selection, confirm completion, open dispute, reclaim escrow.
 * 9. Job Application & Execution (Provider): Apply for job, cancel application, submit result, claim payment.
 * 10. Dispute Resolution Functions: Open dispute, admin resolution (placeholder).
 * 11. Utility/View Functions: Get contract state, get provider info, get job info, list jobs.
 */

/**
 * @dev Function Summary (28 functions, excluding view/pure):
 *
 * Admin/Owner Functions (7):
 * - setProtocolFeeRecipient: Set address receiving protocol fees.
 * - setProtocolFeePercentage: Set percentage fee taken by protocol.
 * - setMinimumProviderStake: Set min ETH stake required for providers.
 * - setJobVerificationPeriod: Set time requester has to verify results.
 * - setUnstakingPeriod: Set cooldown period for provider stake withdrawal.
 * - withdrawProtocolFees: Owner withdraws accumulated protocol fees.
 * - adminResolveDispute: Owner makes a final decision on a dispute (placeholder).
 *
 * Provider Management (6):
 * - registerProvider: Register as a compute provider (requires stake).
 * - updateProviderCapabilities: Update description of services/hardware.
 * - stakeProvider: Add more ETH to provider stake.
 * - unstakeProvider: Initiate withdrawal of stake (starts cooldown).
 * - withdrawUnstakedAmount: Withdraw stake after unstaking period.
 * - unregisterProvider: Gracefully exit as a provider (requires no active jobs/pending unstake).
 *
 * Job Creation & Management (Requester) (8):
 * - createJobRequest: Create a new compute job request (requires escrow payment).
 * - updateJobRequest: Update job details before a provider is selected.
 * - cancelJobRequest: Cancel a job request before a provider is selected.
 * - selectApplicant: Select a provider who applied for the job.
 * - rescindProviderSelection: Cancel selection if provider fails to start within time limit.
 * - confirmJobCompletion: Confirm the provider successfully completed the job.
 * - openDispute: Open a dispute regarding job completion or payment.
 * - reclaimEscrowIfCancelled: Requester reclaims escrow if job is cancelled/timed out before selection.
 *
 * Job Application & Execution (Provider) (4):
 * - applyForJob: Provider applies for an open job request.
 * - cancelJobApplication: Provider cancels their application for a job.
 * - submitComputationResult: Provider submits proof/link to the result of the computation.
 * - claimPayment: Provider claims the escrowed payment after successful completion/timeout.
 *
 * General/Dispute (1):
 * - timeoutJob: Any user can call this to transition a job to TIMED_OUT if deadlines are missed.
 *
 * Utility/View Functions (9+):
 * - getProvider: Get details of a registered provider.
 * - getJob: Get details of a specific job.
 * - listOpenJobs: Get list of job IDs in OPEN state.
 * - listProviderJobs: Get list of job IDs associated with a provider.
 * - listRequesterJobs: Get list of job IDs associated with a requester.
 * - getProviderStake: Get current stake of a provider.
 * - getProtocolFeeBalance: Get the current balance of accumulated protocol fees.
 * - getJobState: Get the current state of a job.
 * - getJobApplicants: Get list of providers who applied for a job.
 * - And getters for various state variables.
 */
```

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Good practice for arithmetic

// Custom error codes for clarity and gas efficiency (ERC-3643 style)
error NotOwner();
error Paused();
error NotPaused();
error ReentrantCall();
error ProviderNotRegistered();
error JobDoesNotExist();
error JobNotInState();
error NotJobRequester();
error NotJobProvider();
error NotJobParticipant();
error InvalidStakeAmount();
error InsufficientStake();
error StakeWithdrawalLocked();
error NoUnstakePending();
error UnstakePeriodNotElapsed();
error JobAlreadyHasProvider();
error NotJobApplicant();
error JobDeadlineMissed();
error VerificationPeriodNotElapsed();
error VerificationPeriodStillActive();
error DisputePeriodStillActive();
error DisputePeriodElapsed();
error DisputeAlreadyOpen();
error JobNotCompleted();
error FeePercentageTooHigh();
error ZeroAddressNotAllowed();
error InvalidJobUpdate();
error JobStillActive();
error UnregisterFailedActiveJobs();

contract DecentralizedAIComputeMarketplace is Ownable, Pausable, ReentrancyGuard {
    using SafeMath for uint256;

    // --- State Variables ---
    uint256 public protocolFeePercentage; // e.g., 5 = 5%
    address payable public protocolFeeRecipient;
    uint256 public minimumProviderStake; // Minimum ETH required to be a provider
    uint256 public jobVerificationPeriod; // Time (seconds) for requester to verify result
    uint256 public unstakingPeriod; // Time (seconds) after unstake request before withdrawal

    uint256 private nextJobId; // Counter for unique job IDs

    // --- Enums ---
    enum JobState {
        OPEN,               // Job is available for providers to apply
        APPLICATIONS_CLOSED, // Job is under review by requester
        ASSIGNED,           // Provider selected, waiting for provider to confirm start
        COMPUTING,          // Provider is working on the job
        VERIFICATION_PENDING, // Provider submitted result, requester needs to verify
        COMPLETED,          // Job successfully completed, payment released
        CANCELLED,          // Job cancelled by requester before assignment
        TIMED_OUT,          // Job timed out due to inactivity/missed deadline
        DISPUTE_OPEN,       // Job is under dispute resolution
        FAILED              // Job failed (e.g., dispute resolved against provider)
    }

    // --- Structs ---
    struct Provider {
        address payable providerAddress;
        string capabilities; // e.g., "GPU: NVIDIA V100, RAM: 128GB"
        bool isRegistered;
        uint256 registeredTimestamp;
        uint256 totalJobsCompleted;
        uint256 totalReputationPoints; // Basic reputation, could be expanded
    }

    struct Job {
        uint256 jobId;
        address payable requester;
        address payable provider; // Assigned provider address (0x0 if none)
        string description;     // Task description (e.g., "Train CNN on ImageNet")
        string inputDataLink;   // IPFS hash or URL for input data
        string outputDataLink;  // IPFS hash or URL for result data
        uint256 budget;         // ETH amount offered for the job
        JobState state;
        uint256 creationTimestamp;
        uint256 assignmentTimestamp; // When provider was assigned
        uint256 resultSubmissionTimestamp; // When provider submitted result
        uint256 disputeOpenTimestamp; // When dispute was opened
        uint256 deadline;       // Deadline for provider to complete the job (optional)
        address[] applicants;   // List of providers who applied
    }

    struct StakeInfo {
        uint256 amount;
        uint256 unstakeRequestTimestamp; // 0 if no unstake is pending
    }

    // --- Mappings ---
    mapping(address => Provider) public providers;
    mapping(address => StakeInfo) public providerStakes;
    mapping(uint256 => Job) public jobs;
    mapping(address => uint256) public requesterEscrows; // ETH held for jobs
    mapping(uint256 => address[]) private jobApplicants; // Separate mapping for applicants to save gas in Job struct

    // --- Events ---
    event ProtocolFeeRecipientUpdated(address indexed newRecipient);
    event ProtocolFeePercentageUpdated(uint256 newPercentage);
    event MinimumProviderStakeUpdated(uint256 newStake);
    event JobVerificationPeriodUpdated(uint256 newPeriod);
    event UnstakingPeriodUpdated(uint256 newPeriod);
    event ProtocolFeesWithdrawn(address indexed recipient, uint256 amount);

    event ProviderRegistered(address indexed provider, string capabilities);
    event ProviderCapabilitiesUpdated(address indexed provider, string capabilities);
    event ProviderStaked(address indexed provider, uint256 amount);
    event ProviderUnstakeRequested(address indexed provider, uint256 amount, uint256 unlockTime);
    event ProviderStakeWithdrawn(address indexed provider, uint256 amount);
    event ProviderUnregistered(address indexed provider);

    event JobCreated(uint256 indexed jobId, address indexed requester, uint256 budget, string description);
    event JobUpdated(uint256 indexed jobId, string description, string inputDataLink, uint256 budget);
    event JobCancelled(uint256 indexed jobId, address indexed requester);
    event JobApplicantApplied(uint256 indexed jobId, address indexed provider);
    event JobApplicantCancelled(uint256 indexed jobId, address indexed provider);
    event ProviderSelected(uint256 indexed jobId, address indexed requester, address indexed provider);
    event ProviderSelectionRescinded(uint256 indexed jobId, address indexed requester, address indexed provider);
    event ComputationResultSubmitted(uint256 indexed jobId, address indexed provider, string outputDataLink);
    event JobCompleted(uint256 indexed jobId, address indexed requester, address indexed provider, uint256 paymentAmount);
    event JobTimedOut(uint256 indexed jobId, JobState fromState, JobState toState);
    event JobFailed(uint256 indexed jobId, JobState fromState, string reason);

    event DisputeOpened(uint256 indexed jobId, address indexed party, string reason);
    event DisputeResolved(uint256 indexed jobId, JobState finalState, string resolutionDetails);

    // --- Modifiers ---
    modifier onlyProvider(address _provider) {
        if (!providers[_provider].isRegistered) revert ProviderNotRegistered();
        _;
    }

    modifier onlyJobRequester(uint256 _jobId) {
        if (jobs[_jobId].requester != msg.sender) revert NotJobRequester();
        _;
    }

    modifier onlyJobProvider(uint256 _jobId) {
        if (jobs[_jobId].provider != msg.sender) revert NotJobProvider();
        _;
    }

    modifier onlyJobParticipant(uint256 _jobId) {
        if (jobs[_jobId].requester != msg.sender && jobs[_jobId].provider != msg.sender) revert NotJobParticipant();
        _;
    }

    modifier jobExists(uint256 _jobId) {
        if (jobs[_jobId].requester == address(0)) revert JobDoesNotExist(); // Requester address is 0x0 for uninitialized struct
        _;
    }

    modifier jobInState(uint256 _jobId, JobState _expectedState) {
        if (jobs[_jobId].state != _expectedState) revert JobNotInState();
        _;
    }

    // --- Constructor ---
    constructor(address payable _protocolFeeRecipient, uint256 _protocolFeePercentage, uint256 _minimumProviderStake, uint256 _jobVerificationPeriod, uint256 _unstakingPeriod) Ownable(msg.sender) {
        if (_protocolFeeRecipient == address(0)) revert ZeroAddressNotAllowed();
        if (_protocolFeePercentage > 100) revert FeePercentageTooHigh();
        protocolFeeRecipient = _protocolFeeRecipient;
        protocolFeePercentage = _protocolFeePercentage;
        minimumProviderStake = _minimumProviderStake;
        jobVerificationPeriod = _jobVerificationPeriod;
        unstakingPeriod = _unstakingPeriod;
        nextJobId = 1;
    }

    // --- Admin Functions (Ownable) ---

    /**
     * @dev Sets the address that receives protocol fees.
     * @param _newRecipient The new recipient address.
     */
    function setProtocolFeeRecipient(address payable _newRecipient) external onlyOwner {
        if (_newRecipient == address(0)) revert ZeroAddressNotAllowed();
        protocolFeeRecipient = _newRecipient;
        emit ProtocolFeeRecipientUpdated(_newRecipient);
    }

    /**
     * @dev Sets the percentage of job budget taken as protocol fee.
     * @param _newPercentage The new fee percentage (0-100).
     */
    function setProtocolFeePercentage(uint256 _newPercentage) external onlyOwner {
        if (_newPercentage > 100) revert FeePercentageTooHigh();
        protocolFeePercentage = _newPercentage;
        emit ProtocolFeePercentageUpdated(_newPercentage);
    }

    /**
     * @dev Sets the minimum ETH stake required for providers.
     * @param _newStake The new minimum stake amount.
     */
    function setMinimumProviderStake(uint256 _newStake) external onlyOwner {
        minimumProviderStake = _newStake;
        emit MinimumProviderStakeUpdated(_newStake);
    }

    /**
     * @dev Sets the time period a requester has to verify a submitted result.
     * @param _newPeriod The new verification period in seconds.
     */
    function setJobVerificationPeriod(uint256 _newPeriod) external onlyOwner {
        jobVerificationPeriod = _newPeriod;
        emit JobVerificationPeriodUpdated(_newPeriod);
    }

    /**
     * @dev Sets the cooldown period after a provider requests to unstake.
     * @param _newPeriod The new unstaking period in seconds.
     */
    function setUnstakingPeriod(uint256 _newPeriod) external onlyOwner {
        unstakingPeriod = _newPeriod;
        emit UnstakingPeriodUpdated(_newPeriod);
    }

    /**
     * @dev Allows the owner to withdraw accumulated protocol fees.
     */
    function withdrawProtocolFees() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance.sub(requesterEscrows[address(this)]).sub(providerStakes[address(this)].amount); // Calculate balance not held in escrow/stake
        if (balance == 0) return; // Nothing to withdraw

        // Simple transfer - safer than call for basic ETH transfer, but check result if using call
        (bool success,) = protocolFeeRecipient.call{value: balance}("");
        require(success, "Withdrawal failed"); // Use require with call for safety

        emit ProtocolFeesWithdrawn(protocolFeeRecipient, balance);
    }

    /**
     * @dev Resolves a dispute. Intended to be called by an admin or a trusted oracle.
     *      NOTE: This is a basic placeholder. A real decentralized dispute system
     *      would be much more complex (e.g., Schelling game, voting, Kleros integration).
     * @param _jobId The ID of the job in dispute.
     * @param _resolveInFavorOfRequester True if resolving in favor of the requester, false for provider.
     * @param _resolutionDetails Details about the resolution.
     */
    function adminResolveDispute(uint256 _jobId, bool _resolveInFavorOfRequester, string calldata _resolutionDetails)
        external
        onlyOwner // Or replace with a trusted oracle/DAO check
        jobExists(_jobId)
        jobInState(_jobId, JobState.DISPUTE_OPEN)
        nonReentrant
    {
        Job storage job = jobs[_jobId];

        if (_resolveInFavorOfRequester) {
            // Refund requester, potentially penalize provider stake (optional, not implemented here)
            uint256 refundAmount = job.budget;
            // Assuming job.budget was already moved from requesterEscrows to contract balance on selection
            // Need to track job specific escrow better or handle this refund logic carefully.
            // Let's assume for simplicity the full budget is escrowed and now released back.
             // Re-add to requester's escrow mapping first if needed, or just send directly
             // Assuming initial escrow amount is tracked separately or remains associated with the job ID conceptually.
             // Let's use the job.budget as the refund amount from the contract's ETH balance.

            (bool success,) = job.requester.call{value: refundAmount}("");
            require(success, "Refund to requester failed");

            job.state = JobState.FAILED; // Job failed from provider's perspective
             emit JobFailed(_jobId, JobState.DISPUTE_OPEN, "Resolved in favor of requester");

        } else {
            // Pay provider, potentially penalize requester stake (optional, not implemented here)
             // This is similar logic to claimPayment.
            uint256 paymentAmount = job.budget;
            uint256 feeAmount = paymentAmount.mul(protocolFeePercentage).div(100);
            uint256 providerAmount = paymentAmount.sub(feeAmount);

             (bool successProvider,) = job.provider.call{value: providerAmount}("");
            require(successProvider, "Payment to provider failed");

            // Fee already stays in contract, claimed by owner via withdrawProtocolFees

            job.state = JobState.COMPLETED; // Job completed from provider's perspective
             emit JobCompleted(_jobId, job.requester, job.provider, providerAmount);

        }

         emit DisputeResolved(_jobId, job.state, _resolutionDetails);
    }


    // --- Provider Management Functions ---

    /**
     * @dev Registers the caller as a compute provider. Requires staking a minimum amount.
     * @param _capabilities Description of the provider's compute capabilities.
     */
    function registerProvider(string calldata _capabilities) external payable whenNotPaused nonReentrant {
        if (providers[msg.sender].isRegistered) revert("Provider already registered");
        if (msg.value < minimumProviderStake) revert InsufficientStake();
        if (msg.sender == address(0)) revert ZeroAddressNotAllowed();

        providers[msg.sender] = Provider({
            providerAddress: payable(msg.sender),
            capabilities: _capabilities,
            isRegistered: true,
            registeredTimestamp: block.timestamp,
            totalJobsCompleted: 0,
            totalReputationPoints: 0 // Start with 0
        });

        providerStakes[msg.sender].amount = providerStakes[msg.sender].amount.add(msg.value);

        emit ProviderRegistered(msg.sender, _capabilities);
        emit ProviderStaked(msg.sender, msg.value);
    }

    /**
     * @dev Updates the capabilities description for a registered provider.
     * @param _capabilities The new capabilities description.
     */
    function updateProviderCapabilities(string calldata _capabilities) external whenNotPaused onlyProvider(msg.sender) {
        providers[msg.sender].capabilities = _capabilities;
        emit ProviderCapabilitiesUpdated(msg.sender, _capabilities);
    }

    /**
     * @dev Adds more ETH to the provider's stake.
     */
    function stakeProvider() external payable whenNotPaused nonReentrant onlyProvider(msg.sender) {
        if (msg.value == 0) revert InvalidStakeAmount();
        providerStakes[msg.sender].amount = providerStakes[msg.sender].amount.add(msg.value);
        emit ProviderStaked(msg.sender, msg.value);
    }

    /**
     * @dev Initiates the process of unstaking some or all of the provider's stake.
     *      Funds become available after the unstaking period.
     * @param _amount The amount to unstake.
     */
    function unstakeProvider(uint256 _amount) external whenNotPaused nonReentrant onlyProvider(msg.sender) {
        StakeInfo storage stakeInfo = providerStakes[msg.sender];

        // Check if there's already a pending unstake
        if (stakeInfo.unstakeRequestTimestamp != 0) revert StakeWithdrawalLocked();

        // Ensure provider maintains minimum stake if not unstaking everything
        if (stakeInfo.amount.sub(_amount) < minimumProviderStake && stakeInfo.amount.sub(_amount) != 0) {
             revert InsufficientStake(); // Cannot go below minimum unless unstaking everything
        }

        if (_amount == 0 || stakeInfo.amount < _amount) revert InvalidStakeAmount();

        stakeInfo.amount = stakeInfo.amount.sub(_amount); // Reduce active stake immediately
        stakeInfo.unstakeRequestTimestamp = block.timestamp; // Mark when unstake started
        // The _amount being unstaked is conceptually moved to a 'pending withdrawal' state
        // within the contract's balance, tracked by the unstakeRequestTimestamp and the *reduced* stakeInfo.amount.
        // The contract's total balance remains the same, but the mapping reflects which part is active stake vs pending withdrawal.
        // A separate mapping for pending withdrawals could be clearer, but this approach saves gas by reusing StakeInfo.

        emit ProviderUnstakeRequested(msg.sender, _amount, block.timestamp + unstakingPeriod);
    }

     /**
      * @dev Withdraws the unstaked amount after the unstaking period has elapsed.
      *      Can only be called if a pending unstake request exists and the time is up.
      */
     function withdrawUnstakedAmount() external whenNotPaused nonReentrant onlyProvider(msg.sender) {
        StakeInfo storage stakeInfo = providerStakes[msg.sender];

         // Check if there's a pending unstake request
         if (stakeInfo.unstakeRequestTimestamp == 0) revert NoUnstakePending();

         // Check if the unstaking period has elapsed
         if (block.timestamp < stakeInfo.unstakeRequestTimestamp.add(unstakingPeriod)) revert UnstakePeriodNotElapsed();

         // Calculate the amount to withdraw. This is the *difference* between the stake amount
         // *before* unstake was requested and the current (reduced) stake amount.
         // To do this cleanly, we need to store the amount requested to unstake.
         // Let's modify the StakeInfo struct or add a new mapping for pending withdrawals.

         // ALTERNATIVE/BETTER Stake Management:
         // StakeInfo { uint256 activeStake; uint256 pendingWithdrawal; uint256 withdrawUnlockTime; }
         // unstakeProvider: move amount from activeStake to pendingWithdrawal, set unlockTime.
         // withdrawUnstakedAmount: check unlockTime, transfer pendingWithdrawal, reset pendingWithdrawal/unlockTime.

         // Let's refactor StakeInfo and unstake/withdraw based on the better model.
         revert("Refactor needed for pending stake withdrawal tracking"); // Placeholder for refactor

         // --- Refactored StakeInfo ---
     }

     // --- Refactored StakeInfo and related functions ---
     struct StakeInfoRefactored {
        uint256 activeStake;
        uint256 pendingWithdrawal;
        uint256 withdrawUnlockTime; // Timestamp when pendingWithdrawal can be withdrawn (0 if none)
     }
     mapping(address => StakeInfoRefactored) public providerStakesRefactored;

     // Modify registerProvider to use Refactored struct
     function registerProviderRefactored(string calldata _capabilities) external payable whenNotPaused nonReentrant {
        if (providers[msg.sender].isRegistered) revert("Provider already registered");
        if (msg.value < minimumProviderStake) revert InsufficientStake();
        if (msg.sender == address(0)) revert ZeroAddressNotAllowed();

        providers[msg.sender] = Provider({
            providerAddress: payable(msg.sender),
            capabilities: _capabilities,
            isRegistered: true,
            registeredTimestamp: block.timestamp,
            totalJobsCompleted: 0,
            totalReputationPoints: 0
        });

        providerStakesRefactored[msg.sender].activeStake = providerStakesRefactored[msg.sender].activeStake.add(msg.value);

        emit ProviderRegistered(msg.sender, _capabilities);
        emit ProviderStaked(msg.sender, msg.value);
    }

    // Modify stakeProvider to use Refactored struct
    function stakeProviderRefactored() external payable whenNotPaused nonReentrant onlyProvider(msg.sender) {
        if (msg.value == 0) revert InvalidStakeAmount();
        providerStakesRefactored[msg.sender].activeStake = providerStakesRefactored[msg.sender].activeStake.add(msg.value);
        emit ProviderStaked(msg.sender, msg.value);
    }

    // Modify unstakeProvider to use Refactored struct
    function unstakeProviderRefactored(uint256 _amount) external whenNotPaused nonReentrant onlyProvider(msg.sender) {
        StakeInfoRefactored storage stakeInfo = providerStakesRefactored[msg.sender];

        // Check if there's already a pending unstake
        if (stakeInfo.pendingWithdrawal > 0) revert StakeWithdrawalLocked();

        // Ensure provider maintains minimum stake if not unstaking everything
        if (stakeInfo.activeStake.sub(_amount) < minimumProviderStake && stakeInfo.activeStake.sub(_amount) != 0) {
             revert InsufficientStake(); // Cannot go below minimum unless unstaking everything
        }

        if (_amount == 0 || stakeInfo.activeStake < _amount) revert InvalidStakeAmount();

        stakeInfo.activeStake = stakeInfo.activeStake.sub(_amount);
        stakeInfo.pendingWithdrawal = _amount;
        stakeInfo.withdrawUnlockTime = block.timestamp.add(unstakingPeriod);

        emit ProviderUnstakeRequested(msg.sender, _amount, stakeInfo.withdrawUnlockTime);
    }

    // Modify withdrawUnstakedAmount to use Refactored struct
    function withdrawUnstakedAmountRefactored() external whenNotPaused nonReentrant onlyProvider(msg.sender) {
        StakeInfoRefactored storage stakeInfo = providerStakesRefactored[msg.sender];

        // Check if there's a pending unstake amount
        if (stakeInfo.pendingWithdrawal == 0) revert NoUnstakePending();

        // Check if the unstaking period has elapsed
        if (block.timestamp < stakeInfo.withdrawUnlockTime) revert UnstakePeriodNotElapsed();

        uint256 amountToWithdraw = stakeInfo.pendingWithdrawal;
        stakeInfo.pendingWithdrawal = 0;
        stakeInfo.withdrawUnlockTime = 0; // Reset

        (bool success,) = payable(msg.sender).call{value: amountToWithdraw}("");
        require(success, "Stake withdrawal failed");

        emit ProviderStakeWithdrawn(msg.sender, amountToWithdraw);
    }

    // Clean up the old mappings (optional, but good practice if refactoring)
    // mapping(address => StakeInfo) private providerStakes; // Mark as deprecated or remove after migration
    // mapping(address => uint256) public providerStakesAmount; // Use providerStakesRefactored.activeStake + .pendingWithdrawal for total

    // We will proceed using the Refactored stake functions and struct names
    // Need to ensure minimum stake checks use activeStake going forward.
    // Also need to consider what happens to stake if a provider is assigned a job then tries to unstake.
    // For simplicity now, let's prevent unregister/unstake if provider has active jobs.

    /**
     * @dev Allows a provider to unregister. Requires no active jobs or pending unstakes.
     *      Does NOT withdraw stake automatically - unstake/withdraw must happen separately.
     */
    function unregisterProvider() external whenNotPaused nonReentrant onlyProvider(msg.sender) {
        // Check if provider has any active jobs (ASSIGNED, COMPUTING, VERIFICATION_PENDING, DISPUTE_OPEN)
        // This requires iterating over provider's jobs, which is expensive.
        // A mapping tracking active job counts per provider would be better.
        // For simplicity in this example, we'll skip the active job check, assuming
        // providers manage their job completion before unregistering.
        // A robust contract needs this check or a mechanism to handle jobs mid-completion.

        if (providerStakesRefactored[msg.sender].activeStake > 0 || providerStakesRefactored[msg.sender].pendingWithdrawal > 0) {
             revert("Cannot unregister with active or pending stake");
        }

        // Check for active jobs (simplified check)
        // This would require storing job IDs per provider, e.g., mapping(address => uint256[]) providerJobIds;
        // And checking states of those jobs. This is omitted for conciseness in this example.
        // If active jobs exist, UNregisterFailedActiveJobs should be reverted.

        providers[msg.sender].isRegistered = false;
        // Could also clear capabilities etc. to save a tiny bit of space, but bool isRegistered is sufficient.

        emit ProviderUnregistered(msg.sender);
    }


    // --- Job Creation & Management (Requester) ---

    /**
     * @dev Creates a new job request. Requires sending the full budget as escrow.
     * @param _description Description of the AI task.
     * @param _inputDataLink Link to input data (IPFS hash, URL).
     * @param _deadline Deadline for the provider to complete the job (timestamp). 0 for no deadline.
     */
    function createJobRequest(
        string calldata _description,
        string calldata _inputDataLink,
        uint256 _deadline
    ) external payable whenNotPaused nonReentrant {
        if (msg.value == 0) revert InvalidStakeAmount(); // Budget cannot be zero
        if (msg.sender == address(0)) revert ZeroAddressNotAllowed();

        uint256 currentJobId = nextJobId;
        nextJobId++;

        jobs[currentJobId] = Job({
            jobId: currentJobId,
            requester: payable(msg.sender),
            provider: payable(address(0)), // No provider assigned yet
            description: _description,
            inputDataLink: _inputDataLink,
            outputDataLink: "", // No result yet
            budget: msg.value,
            state: JobState.OPEN,
            creationTimestamp: block.timestamp,
            assignmentTimestamp: 0,
            resultSubmissionTimestamp: 0,
            disputeOpenTimestamp: 0,
            deadline: _deadline,
            applicants: new address[](0) // Applicants tracked in separate mapping
        });

        // Escrow the payment. We use a mapping to track per-requester escrow.
        // This assumes the full budget is held until job completion or cancellation.
        requesterEscrows[msg.sender] = requesterEscrows[msg.sender].add(msg.value);

        emit JobCreated(currentJobId, msg.sender, msg.value, _description);
    }

     /**
      * @dev Allows the requester to update job details while in the OPEN state.
      * @param _jobId The ID of the job to update.
      * @param _description New description.
      * @param _inputDataLink New input data link.
      * @param _deadline New deadline (0 for no deadline).
      */
    function updateJobRequest(
        uint256 _jobId,
        string calldata _description,
        string calldata _inputDataLink,
        uint256 _deadline
    ) external whenNotPaused jobExists(_jobId) onlyJobRequester(_jobId) jobInState(_jobId, JobState.OPEN) {
         jobs[_jobId].description = _description;
         jobs[_jobId].inputDataLink = _inputDataLink;
         jobs[_jobId].deadline = _deadline; // Can update deadline while open

         emit JobUpdated(_jobId, _description, _inputDataLink, _deadline);
    }

    /**
     * @dev Allows the requester to cancel a job request if no provider has been selected yet.
     *      Refunds the escrowed ETH.
     * @param _jobId The ID of the job to cancel.
     */
    function cancelJobRequest(uint256 _jobId)
        external
        whenNotPaused
        jobExists(_jobId)
        onlyJobRequester(_jobId)
        jobInState(_jobId, JobState.OPEN)
        nonReentrant
    {
        Job storage job = jobs[_jobId];
        uint256 refundAmount = job.budget;

        // Decrease requester's total escrow tracking
        requesterEscrows[msg.sender] = requesterEscrows[msg.sender].sub(refundAmount);

        // Refund the ETH directly to the requester
        (bool success,) = job.requester.call{value: refundAmount}("");
        require(success, "Escrow refund failed");

        job.state = JobState.CANCELLED;
        emit JobCancelled(_jobId, msg.sender);

        // Clear applicants list for the cancelled job
        delete jobApplicants[_jobId];
    }

    /**
     * @dev Allows the requester to select a provider from the applicants list.
     *      Transitions job to ASSIGNED state.
     * @param _jobId The ID of the job.
     * @param _provider The address of the provider to select.
     */
    function selectApplicant(uint256 _jobId, address _provider)
        external
        whenNotPaused
        jobExists(_jobId)
        onlyJobRequester(_jobId)
        jobInState(_jobId, JobState.OPEN) // Or maybe APPLICATIONS_CLOSED if that state is added
        onlyProvider(_provider) // Selected address must be a registered provider
    {
        Job storage job = jobs[_jobId];

        // Optional: Check if the selected provider actually applied.
        bool found = false;
        for (uint i = 0; i < jobApplicants[_jobId].length; i++) {
            if (jobApplicants[_jobId][i] == _provider) {
                found = true;
                break;
            }
        }
        if (!found) revert NotJobApplicant(); // Provider didn't apply

        job.provider = payable(_provider);
        job.assignmentTimestamp = block.timestamp; // Record assignment time
        job.state = JobState.ASSIGNED; // Provider is now assigned

        // Clear applicants list once someone is selected
        delete jobApplicants[_jobId];

        emit ProviderSelected(_jobId, msg.sender, _provider);
    }

    /**
     * @dev Allows the requester to rescind the provider selection if the provider
     *      fails to transition the job out of the ASSIGNED state within a reasonable time.
     *      (NOTE: This contract doesn't enforce provider action in ASSIGNED state yet,
     *      a state like 'PROVIDER_ACKNOWLEDGE' could be added).
     *      For now, this function acts as a way to un-assign before COMPUTING starts.
     *      Refunds requester escrow, job goes back to OPEN or CANCELLED.
     * @param _jobId The ID of the job.
     */
    function rescindProviderSelection(uint256 _jobId)
        external
        whenNotPaused
        jobExists(_jobId)
        onlyJobRequester(_jobId)
        jobInState(_jobId, JobState.ASSIGNED)
        nonReentrant
    {
        Job storage job = jobs[_jobId];

        // Optionally add a minimum time before rescinding is allowed,
        // e.g., require(block.timestamp > job.assignmentTimestamp + minAckPeriod)

        uint256 refundAmount = job.budget;

        // Decrease requester's total escrow tracking
        requesterEscrows[msg.sender] = requesterEscrows[msg.sender].sub(refundAmount);

        // Refund the ETH directly to the requester
        (bool success,) = job.requester.call{value: refundAmount}("");
        require(success, "Escrow refund failed on rescind");

        // Requester can choose to re-open for applications or cancel completely
        // Let's make it CANCELLED to simplify the state logic.
        job.state = JobState.CANCELLED;
        job.provider = payable(address(0)); // Un-assign provider

        emit ProviderSelectionRescinded(_jobId, msg.sender, job.provider);
        emit JobCancelled(_jobId, msg.sender); // Also emit cancelled event
    }


    /**
     * @dev Confirms successful job completion by the requester.
     *      Transitions job to COMPLETED state and triggers payment to provider.
     * @param _jobId The ID of the job.
     */
    function confirmJobCompletion(uint256 _jobId)
        external
        whenNotPaused
        jobExists(_jobId)
        onlyJobRequester(_jobId)
        jobInState(_jobId, JobState.VERIFICATION_PENDING)
        nonReentrant
    {
        Job storage job = jobs[_jobId];

        // Check if verification period is still active (optional, can allow early confirmation)
        // require(block.timestamp < job.resultSubmissionTimestamp + jobVerificationPeriod, VerificationPeriodElapsed());

        // Calculate fees and amounts
        uint256 paymentAmount = job.budget;
        uint256 feeAmount = paymentAmount.mul(protocolFeePercentage).div(100);
        uint256 providerAmount = paymentAmount.sub(feeAmount);

        // Decrease requester's total escrow tracking by the job budget (which is now being paid out)
        requesterEscrows[msg.sender] = requesterEscrows[msg.sender].sub(job.budget);

        // Pay the provider
        (bool successProvider,) = job.provider.call{value: providerAmount}("");
        require(successProvider, "Payment to provider failed");

        // Protocol fee remains in contract and can be withdrawn by owner

        job.state = JobState.COMPLETED;

        // Update provider stats (basic reputation)
        if (providers[job.provider].isRegistered) { // Only update if provider is still registered
             providers[job.provider].totalJobsCompleted = providers[job.provider].totalJobsCompleted.add(1);
             // Basic positive reputation boost
             providers[job.provider].totalReputationPoints = providers[job.provider].totalReputationPoints.add(1);
        }

        emit JobCompleted(_jobId, msg.sender, job.provider, providerAmount);
    }

    /**
     * @dev Allows either the requester or provider to open a dispute.
     *      Transitions job to DISPUTE_OPEN state.
     * @param _jobId The ID of the job.
     * @param _reason Brief reason for the dispute.
     */
    function openDispute(uint256 _jobId, string calldata _reason)
        external
        whenNotPaused
        jobExists(_jobId)
        onlyJobParticipant(_jobId)
        nonReentrant
    {
        Job storage job = jobs[_jobId];

        // Allow dispute from ASSIGNED, COMPUTING, VERIFICATION_PENDING states
        if (job.state != JobState.ASSIGNED &&
            job.state != JobState.COMPUTING &&
            job.state != JobState.VERIFICATION_PENDING) {
             revert JobNotInState();
        }

        // Prevent opening dispute if one is already open
        if (job.state == JobState.DISPUTE_OPEN) revert DisputeAlreadyOpen();

        job.state = JobState.DISPUTE_OPEN;
        job.disputeOpenTimestamp = block.timestamp;

        emit DisputeOpened(_jobId, msg.sender, _reason);

        // NOTE: Actual dispute resolution logic (voting, evidence, etc.) is complex
        // and likely happens off-chain or involves another protocol (like Kleros).
        // The `adminResolveDispute` is a simple placeholder.
    }

    /**
     * @dev Allows the requester to reclaim their escrowed funds if the job
     *      was cancelled or timed out BEFORE a provider was selected/assigned.
     * @param _jobId The ID of the job.
     */
    function reclaimEscrowIfCancelled(uint256 _jobId)
         external
         whenNotPaused
         jobExists(_jobId)
         onlyJobRequester(_jobId)
         nonReentrant
    {
         Job storage job = jobs[_jobId];

         // Only allow if the job is in CANCELLED or TIMED_OUT state AND had no provider assigned
         if (job.provider != address(0)) revert JobAlreadyHasProvider();
         if (job.state != JobState.CANCELLED && job.state != JobState.TIMED_OUT) revert JobNotInState();

         uint256 refundAmount = job.budget;

         // Decrease requester's total escrow tracking
         requesterEscrows[msg.sender] = requesterEscrows[msg.sender].sub(refundAmount);

         // Refund the ETH directly to the requester
         (bool success,) = job.requester.call{value: refundAmount}("");
         require(success, "Escrow refund failed");

         // Mark the job as fully settled/refunded if needed, or rely on state (CANCELLED/TIMED_OUT)
         // Could add a REFUNDED state, but let's keep it simple.

         emit ProtocolFeesWithdrawn(job.requester, refundAmount); // Re-using event, maybe create EscrowRefunded?
         // Let's create a new event for clarity
         emit EscrowRefunded(_jobId, job.requester, refundAmount);
    }
     event EscrowRefunded(uint256 indexed jobId, address indexed requester, uint256 amount);


    // --- Job Application & Execution (Provider) ---

    /**
     * @dev Allows a registered provider to apply for an open job request.
     * @param _jobId The ID of the job to apply for.
     */
    function applyForJob(uint256 _jobId)
        external
        whenNotPaused
        jobExists(_jobId)
        onlyProvider(msg.sender)
        jobInState(_jobId, JobState.OPEN)
    {
        Job storage job = jobs[_jobId];

        // Check if provider has already applied (basic check, could be optimized)
        for (uint i = 0; i < jobApplicants[_jobId].length; i++) {
            if (jobApplicants[_jobId][i] == msg.sender) {
                revert("Provider already applied");
            }
        }

        jobApplicants[_jobId].push(msg.sender); // Add provider to applicants list

        emit JobApplicantApplied(_jobId, msg.sender);
    }

    /**
     * @dev Allows a provider to cancel their application for a job.
     * @param _jobId The ID of the job.
     */
    function cancelJobApplication(uint256 _jobId)
         external
         whenNotPaused
         jobExists(_jobId)
         onlyProvider(msg.sender)
         jobInState(_jobId, JobState.OPEN)
    {
         address[] storage applicants = jobApplicants[_jobId];
         bool found = false;
         for (uint i = 0; i < applicants.length; i++) {
             if (applicants[i] == msg.sender) {
                 // Remove by swapping with last and popping (gas efficient)
                 applicants[i] = applicants[applicants.length - 1];
                 applicants.pop();
                 found = true;
                 break;
             }
         }

         if (!found) revert NotJobApplicant(); // Provider did not apply for this job

         emit JobApplicantCancelled(_jobId, msg.sender);
    }


    /**
     * @dev Allows the assigned provider to submit the result of the computation.
     *      Transitions job to VERIFICATION_PENDING state.
     * @param _jobId The ID of the job.
     * @param _outputDataLink Link to the output data (IPFS hash, URL).
     */
    function submitComputationResult(uint256 _jobId, string calldata _outputDataLink)
        external
        whenNotPaused
        jobExists(_jobId)
        onlyJobProvider(_jobId)
    {
        Job storage job = jobs[_jobId];

        // Allow submission from COMPUTING or ASSIGNED (if provider skipped COMPUTING state transition)
        if (job.state != JobState.COMPUTING && job.state != JobState.ASSIGNED) {
             revert JobNotInState();
        }

        job.outputDataLink = _outputDataLink;
        job.resultSubmissionTimestamp = block.timestamp;
        job.state = JobState.VERIFICATION_PENDING;

        emit ComputationResultSubmitted(_jobId, msg.sender, _outputDataLink);
    }

     /**
      * @dev Allows the provider to claim payment if the requester confirmed
      *      completion OR the verification period elapsed without dispute.
      *      (NOTE: The logic for elapsed verification period triggering payment is
      *       often handled by a separate callable function or watcher).
      *      This function primarily handles the case where the requester *confirmed* completion.
      *      Automatic payment after timeout would require a different trigger.
      *      Let's make this function callable by anyone *after* verification period expiry if not confirmed/disputed.
      * @param _jobId The ID of the job.
      */
    function claimPayment(uint256 _jobId)
         external
         whenNotPaused
         jobExists(_jobId)
         nonReentrant
    {
         Job storage job = jobs[_jobId];

         // Check if the job is in a state ready for payment
         // Either COMPLETED (requester confirmed)
         // Or VERIFICATION_PENDING AND verification period has elapsed AND no dispute was opened
         bool readyForPayment = (job.state == JobState.COMPLETED) ||
                                 (job.state == JobState.VERIFICATION_PENDING &&
                                  block.timestamp >= job.resultSubmissionTimestamp.add(jobVerificationPeriod) &&
                                  job.disputeOpenTimestamp == 0); // No dispute opened

         if (!readyForPayment) {
              revert JobNotInState(); // Or specific error like "Job not ready for payment"
         }

         // Only the assigned provider or potentially anyone after timeout/completion can trigger this
         if (msg.sender != job.provider && job.state != JobState.VERIFICATION_PENDING) {
             // If not the provider, can only claim if timed out (VERIFICATION_PENDING + timeout)
             revert NotJobProvider(); // Restrict to provider unless timing out
         }


         // Calculate fees and amounts
         uint256 paymentAmount = job.budget;
         uint256 feeAmount = paymentAmount.mul(protocolFeePercentage).div(100);
         uint256 providerAmount = paymentAmount.sub(feeAmount);

         // Decrease requester's total escrow tracking by the job budget (which is now being paid out)
         // This escrow reduction needs to happen ONLY ONCE per job payment.
         // It should probably happen in confirmJobCompletion AND in this claimPayment function
         // IF the state was VERIFICATION_PENDING -> COMPLETED via timeout.
         // Need to ensure it's safe to call multiple times or track if budget is already processed.
         // Let's add a flag or handle this carefully.

         // Add a flag to Job struct: bool budgetProcessed;
         // Or: Only reduce requesterEscrows when payment is sent to provider/requester refund.
         // Let's reduce escrow here if it hasn't been already.

         if (requesterEscrows[job.requester] < job.budget) {
              // This should not happen if escrow tracking is correct, but as a safety...
              // This implies the budget was already moved. We need a way to know if payout happened.
              // Simpler: Only allow claimPayment if state is VERIFICATION_PENDING (timeout case).
              // Let confirmJobCompletion handle the COMPLETED case payment.

              // Refactoring ClaimPayment: Only for timeout scenario from VERIFICATION_PENDING
              revert("Claim payment is only for timeout scenario from Verification Pending"); // Placeholder

         }

         // --- Refactored ClaimPayment (Only for timeout from VERIFICATION_PENDING) ---
     }

     // Refactored ClaimPayment function (renamed or replaced logic)
     // Let's implement a `finalizeJobAfterTimeout` function instead, callable by anyone.

     /**
      * @dev Callable by anyone to finalize a job in VERIFICATION_PENDING state
      *      if the verification period has elapsed without requester action or dispute.
      *      This triggers payment to the provider.
      * @param _jobId The ID of the job.
      */
     function finalizeJobAfterVerificationTimeout(uint256 _jobId)
         external
         whenNotPaused
         jobExists(_jobId)
         jobInState(_jobId, JobState.VERIFICATION_PENDING)
         nonReentrant
     {
         Job storage job = jobs[_jobId];

         // Check if verification period has elapsed AND no dispute was opened
         if (block.timestamp < job.resultSubmissionTimestamp.add(jobVerificationPeriod)) revert VerificationPeriodStillActive();
         if (job.disputeOpenTimestamp != 0) revert DisputeAlreadyOpen(); // Should be checked by jobInState, but double check

         // Calculate fees and amounts
         uint256 paymentAmount = job.budget;
         uint256 feeAmount = paymentAmount.mul(protocolFeePercentage).div(100);
         uint256 providerAmount = paymentAmount.sub(feeAmount);

         // Decrease requester's total escrow tracking
         requesterEscrows[job.requester] = requesterEscrows[job.requester].sub(job.budget);

         // Pay the provider
         (bool successProvider,) = job.provider.call{value: providerAmount}("");
         require(successProvider, "Payment to provider failed after timeout");

         job.state = JobState.COMPLETED; // Job completed due to timeout

         // Update provider stats (basic reputation)
         if (providers[job.provider].isRegistered) { // Only update if provider is still registered
              providers[job.provider].totalJobsCompleted = providers[job.provider].totalJobsCompleted.add(1);
              // No reputation boost for timeout completion? Or smaller boost? Let's give a smaller boost.
              providers[job.provider].totalReputationPoints = providers[job.provider].totalReputationPoints.add(1); // Or add 0.5 points etc. (requires fixed point math)
         }

         emit JobCompleted(_jobId, job.requester, job.provider, providerAmount);
         emit JobTimedOut(_jobId, JobState.VERIFICATION_PENDING, JobState.COMPLETED); // Indicate timeout led to completion
     }


    // --- General/Dispute ---

    /**
     * @dev Allows anyone to transition a job to TIMED_OUT if deadlines are missed.
     *      Applicable if job is ASSIGNED or COMPUTING and job.deadline is set and passed.
     *      Or if job is OPEN and sits too long (requires an admin/protocol-defined timeout for OPEN state).
     *      Let's focus on the provider deadline for now.
     * @param _jobId The ID of the job.
     */
    function timeoutJob(uint256 _jobId)
         external
         whenNotPaused
         jobExists(_jobId)
    {
         Job storage job = jobs[_jobId];
         JobState currentState = job.state;

         bool eligibleForTimeout = false;

         // Timeout if ASSIGNED/COMPUTING and provider deadline passed
         if ((currentState == JobState.ASSIGNED || currentState == JobState.COMPUTING) &&
             job.deadline != 0 && block.timestamp > job.deadline) {
             eligibleForTimeout = true;
         }

         // Could add other timeout conditions, e.g., OPEN for too long, or ASSIGNED but no result submission after X time

         if (!eligibleForTimeout) {
              revert JobDeadlineMissed(); // Or other specific timeout error
         }

         // If timed out while provider was assigned, handle payment/escrow
         if (job.provider != address(0)) {
             // Refund requester, potentially penalize provider stake (optional)
             uint256 refundAmount = job.budget;
             // Decrease requester's total escrow tracking
             requesterEscrows[job.requester] = requesterEscrows[job.requester].sub(refundAmount);

             // Refund the ETH directly to the requester
             (bool success,) = job.requester.call{value: refundAmount}("");
             require(success, "Escrow refund failed on timeout");

             // Could add provider stake slashing here:
             // providerStakesRefactored[job.provider].activeStake = providerStakesRefactored[job.provider].activeStake.sub(slashedAmount);
             // Send slashedAmount to fee recipient or burn it. Omitted for simplicity.
         } else if (currentState == JobState.OPEN) {
             // If timed out in OPEN state, the escrow is still with the requester logically
             // via the requesterEscrows mapping. No ETH movement needed here, just state change.
             // The `reclaimEscrowIfCancelled` function handles the actual ETH transfer if needed.
         } else {
              // Should not happen with current logic
              revert("Timeout logic error");
         }


         job.state = JobState.TIMED_OUT;
         emit JobTimedOut(_jobId, currentState, JobState.TIMED_OUT);

         // Clear applicants if still in OPEN state
         if (currentState == JobState.OPEN) {
             delete jobApplicants[_jobId];
         }
    }


    // --- Utility/View Functions ---

    /**
     * @dev Returns the details of a registered provider.
     * @param _provider The provider's address.
     * @return Provider struct details.
     */
    function getProvider(address _provider) external view returns (Provider memory) {
        if (!providers[_provider].isRegistered) revert ProviderNotRegistered();
        return providers[_provider];
    }

     /**
      * @dev Returns the current stake amount for a provider.
      * @param _provider The provider's address.
      * @return The active stake amount.
      */
     function getProviderStake(address _provider) external view returns (uint256 activeStake, uint256 pendingWithdrawal, uint256 withdrawUnlockTime) {
        StakeInfoRefactored memory stakeInfo = providerStakesRefactored[_provider];
        return (stakeInfo.activeStake, stakeInfo.pendingWithdrawal, stakeInfo.withdrawUnlockTime);
     }

    /**
     * @dev Returns the details of a job.
     * @param _jobId The job ID.
     * @return Job struct details.
     */
    function getJob(uint256 _jobId) external view jobExists(_jobId) returns (Job memory) {
        return jobs[_jobId];
    }

     /**
      * @dev Returns the current state of a job.
      * @param _jobId The job ID.
      * @return The job state enum.
      */
     function getJobState(uint256 _jobId) external view jobExists(_jobId) returns (JobState) {
         return jobs[_jobId].state;
     }

     /**
      * @dev Returns the list of addresses that have applied for a job.
      * @param _jobId The job ID.
      * @return An array of applicant addresses.
      */
     function getJobApplicants(uint256 _jobId) external view jobExists(_jobId) returns (address[] memory) {
        // Ensure the job is in a state where applicants are relevant (OPEN or APPLICATIONS_CLOSED if implemented)
        JobState currentState = jobs[_jobId].state;
        if (currentState != JobState.OPEN /* && currentState != JobState.APPLICATIONS_CLOSED */) {
            // Returning an empty array or reverting could be options. Empty array is less disruptive.
            // Consider state transitions clear the applicants array.
            return new address[](0);
        }
         return jobApplicants[_jobId];
     }


    // Add more view functions as needed for UI (listing open jobs, provider's active jobs, etc.)
    // Listing functions that require iterating over all jobs are gas-expensive and
    // generally handled better by off-chain indexing (TheGraph). We can provide basic ones.

    // NOTE: Implementing functions to list *all* open jobs or a user's jobs
    // efficiently on-chain is difficult. The following view functions
    // are placeholders or assume a limited number of total jobs/user jobs.
    // For large-scale applications, use off-chain indexing.

    /**
     * @dev Returns a list of Job IDs in the OPEN state.
     *      NOTE: This is inefficient for a large number of jobs. Use off-chain indexing.
     * @return An array of open job IDs.
     */
    function listOpenJobs() external view returns (uint256[] memory) {
        // Cannot easily iterate mappings on-chain. Requires storing job IDs in an array,
        // which is also complex to manage (adding/removing).
        // Placeholder: Would iterate over all existing job IDs (if stored in an array)
        // or rely on off-chain indexing of JobCreated events.
        // Returning an empty array as a realistic limitation of on-chain view functions for lists.
        return new uint256[](0);
    }

     /**
      * @dev Returns a list of Job IDs assigned to a provider.
      *      NOTE: This is inefficient without a mapping tracking jobs per provider. Use off-chain indexing.
      * @param _provider The provider's address.
      * @return An array of job IDs assigned to the provider.
      */
     function listProviderJobs(address _provider) external view returns (uint256[] memory) {
          // Placeholder: Requires mapping(address => uint256[]) providerToJobs;
          // return providerToJobs[_provider];
          return new uint256[](0);
     }

     /**
      * @dev Returns a list of Job IDs created by a requester.
      *      NOTE: This is inefficient without a mapping tracking jobs per requester. Use off-chain indexing.
      * @param _requester The requester's address.
      * @return An array of job IDs created by the requester.
      */
     function listRequesterJobs(address _requester) external view returns (uint256[] memory) {
          // Placeholder: Requires mapping(address => uint256[]) requesterToJobs;
          // return requesterToJobs[_requester];
          return new uint256[](0);
     }


    // Inherited functions from OpenZeppelin:
    // - pause() external onlyOwner
    // - unpause() external onlyOwner
    // - paused() public view returns (bool)
    // - owner() public view returns (address)
    // - renounceOwnership() external onlyOwner
    // - transferOwnership(address newOwner) external onlyOwner
    // - nonReentrant modifier

    // Additional View functions for parameters:
    function getProtocolFeePercentage() external view returns (uint256) { return protocolFeePercentage; }
    function getMinimumProviderStake() external view returns (uint256) { return minimumProviderStake; }
    function getJobVerificationPeriod() external view returns (uint256) { return jobVerificationPeriod; }
    function getUnstakingPeriod() external view returns (uint256) { return unstakingPeriod; }
    function getProtocolFeeBalance() external view returns (uint256) {
         // Total contract balance minus total escrow and total active/pending stake
         uint256 totalEscrowed = 0;
         // Calculating total escrow/stake accurately requires iterating mappings, which is infeasible.
         // A dedicated state variable `totalProtocolFees` incremented on fee collection is needed.
         // For simplicity, return contract balance minus the *known* escrow of the *requesterEscrows* mapping,
         // which isn't perfectly accurate as payment has moved from requesterEscrow to contract balance.
         // A proper system would track accrued fees directly.
         // As a rough estimate:
         uint256 totalStaked = 0;
         // Again, iterating providerStakesRefactored is not feasible.
         // The contract balance minus all outstanding job budgets (before payout) and active stakes
         // would represent fees + ETH available for stake withdrawal.
         // Accurate fee balance needs a separate state variable.
         return address(this).balance; // WARNING: This is *total* balance, not just fees. Accurate balance tracking needs refactor.
     }

     // --- Refactored Fee Tracking ---
     uint256 public totalProtocolFeesAccrued;

     // Modify functions that collect fees (implicitly by sending provider < budget)
     // - finalizeJobAfterVerificationTimeout: fee = paymentAmount.mul(protocolFeePercentage).div(100); totalProtocolFeesAccrued = totalProtocolFeesAccrued.add(fee);
     // - confirmJobCompletion: fee = paymentAmount.mul(protocolFeePercentage).div(100); totalProtocolFeesAccrued = totalProtocolFeesAccrued.add(fee);
     // - adminResolveDispute (if resolved in favor of provider): fee = ...; totalProtocolFeesAccrued = totalProtocolFeesAccrued.add(fee);

     // Modify withdrawProtocolFees to use totalProtocolFeesAccrued and reset it
     function withdrawProtocolFeesRefactored() external onlyOwner nonReentrant {
         uint256 balanceToWithdraw = totalProtocolFeesAccrued;
         if (balanceToWithdraw == 0) return;

         totalProtocolFeesAccrued = 0; // Reset before sending

         (bool success,) = protocolFeeRecipient.call{value: balanceToWithdraw}("");
         require(success, "Protocol fee withdrawal failed");

         emit ProtocolFeesWithdrawn(protocolFeeRecipient, balanceToWithdraw);
     }

     // Replace the placeholder getProtocolFeeBalance with the accurate one
     function getAccruedProtocolFeeBalance() external view returns (uint256) {
         return totalProtocolFeesAccrued;
     }

     // Let's go back and add fee tracking increments and use the refactored withdraw/getter

     // (Adding increments in finalizeJobAfterVerificationTimeout, confirmJobCompletion, adminResolveDispute)
     // Example in finalizeJobAfterVerificationTimeout:
     // ...
     // uint256 feeAmount = paymentAmount.mul(protocolFeePercentage).div(100);
     // uint256 providerAmount = paymentAmount.sub(feeAmount);
     // totalProtocolFeesAccrued = totalProtocolFeesAccrued.add(feeAmount); // Add this line
     // ... rest of function


    // --- Final Function Count Check ---
    // Admin/Owner: setFeeRecipient, setFeePercentage, setMinStake, setVerificationPeriod, setUnstakingPeriod, withdrawProtocolFeesRefactored, adminResolveDispute (7)
    // Provider Management: registerProviderRefactored, updateProviderCapabilities, stakeProviderRefactored, unstakeProviderRefactored, withdrawUnstakedAmountRefactored, unregisterProvider (6)
    // Job Creation/Mgmt (Requester): createJobRequest, updateJobRequest, cancelJobRequest, selectApplicant, rescindProviderSelection, confirmJobCompletion, openDispute, reclaimEscrowIfCancelled (8)
    // Job Application/Execution (Provider): applyForJob, cancelJobApplication, submitComputationResult (3) - ClaimPayment is replaced by finalize...
    // General/Dispute: timeoutJob, finalizeJobAfterVerificationTimeout (2)
    // Total Action/Admin: 7 + 6 + 8 + 3 + 2 = 26 functions. Yes, over 20.

    // View Functions (Example): getProvider, getProviderStake, getJob, getJobState, getJobApplicants, getProtocolFeePercentage, getMinimumProviderStake, getJobVerificationPeriod, getUnstakingPeriod, getAccruedProtocolFeeBalance (10)

    // The contract logic needs the Refactored Stake and Fee functions. I'll include them in the final code block.
    // I will replace the placeholder withdraw and getter functions with the refactored ones.
    // I will add the fee increment logic to the relevant payment functions.
    // I will ensure the provider management functions use the Refactored Stake struct.
    // I will include both `registerProviderRefactored` and `stakeProviderRefactored` but keep the original public names like `registerProvider` for the ABI, mapping them internally. Or just use the Refactored names externally. Let's use Refactored names.
    // Need to update the summary to reflect the Refactored names/logic.


    // --- Refactored Function Names and Implementation ---
    // Replacing original stake/withdraw/register with Refactored versions.
    // Adding fee tracking.
    // Renaming claimPayment to finalizeJobAfterVerificationTimeout.

    // (Self-correction: It's cleaner to just implement the desired logic directly
    // rather than writing placeholders and then replacing. The above thought process
    // helped define the final set of functions and necessary state/structs).

    // The final code will include:
    // - State: protocolFeePercentage, protocolFeeRecipient, minimumProviderStake, jobVerificationPeriod, unstakingPeriod, nextJobId, totalProtocolFeesAccrued
    // - Enums: JobState
    // - Structs: Provider, Job, StakeInfoRefactored
    // - Mappings: providers, jobs, requesterEscrows, jobApplicants, providerStakesRefactored
    // - Events: All listed above (add EscrowRefunded)
    // - Modifiers: onlyOwner, whenNotPaused, whenPaused, nonReentrant, onlyProvider, onlyJobRequester, onlyJobProvider, onlyJobParticipant, jobExists, jobInState
    // - Constructor
    // - Admin Functions (7): setProtocolFeeRecipient, setProtocolFeePercentage, setMinimumProviderStake, setJobVerificationPeriod, setUnstakingPeriod, withdrawProtocolFeesRefactored, adminResolveDispute
    // - Provider Management (6): registerProviderRefactored, updateProviderCapabilities, stakeProviderRefactored, unstakeProviderRefactored, withdrawUnstakedAmountRefactored, unregisterProvider
    // - Job Creation/Mgmt (Requester) (8): createJobRequest, updateJobRequest, cancelJobRequest, selectApplicant, rescindProviderSelection, confirmJobCompletion, openDispute, reclaimEscrowIfCancelled
    // - Job Application/Execution (Provider) (3): applyForJob, cancelJobApplication, submitComputationResult
    // - General/Timeout (2): timeoutJob, finalizeJobAfterVerificationTimeout
    // - View Functions (10+): getProvider, getProviderStakeRefactored, getJob, getJobState, getJobApplicants, listOpenJobs (placeholder), listProviderJobs (placeholder), listRequesterJobs (placeholder), getProtocolFeePercentage, getMinimumProviderStake, getJobVerificationPeriod, getUnstakingPeriod, getAccruedProtocolFeeBalance, getRequesterEscrowBalance.

    // Add getRequesterEscrowBalance view function
    function getRequesterEscrowBalance(address _requester) external view returns (uint256) {
        return requesterEscrows[_requester];
    }


    // Total functions including view: 26 action/admin + 14 view = 40+ functions.
    // Total action/admin: 26 functions. Satisfies >= 20 requirement.

    // Ensure all payment-receiving functions are `payable`.
    // Ensure all state-changing functions have `whenNotPaused`.
    // Ensure `nonReentrant` is on functions sending Ether out.

    // The current code block is the final version after incorporating the refactored logic.

} // End of contract definition

```

---
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title DecentralizedAIComputeMarketplace
 * @dev A smart contract for a decentralized marketplace connecting users who need AI computation
 *      (Requesters) with users who can provide it (Providers).
 *      It manages job creation, provider application/selection, payment escrow, result submission,
 *      verification, and basic dispute flow.
 *      Computation itself happens OFF-CHAIN, while the contract manages the coordination,
 *      payments, and state transitions ON-CHAIN.
 */

/**
 * @dev Outline:
 * 1. State Variables: Store contract parameters, provider info, job info, balances.
 * 2. Enums: Define job states.
 * 3. Structs: Define data structures for Providers, Jobs, and Provider Stake.
 * 4. Events: Signal key state changes.
 * 5. Modifiers: Restrict function access based on role or state.
 * 6. Admin Functions (Ownable): Set parameters, withdraw fees, pause/unpause, resolve disputes.
 * 7. Provider Management Functions: Register, update capabilities, stake, unstake, withdraw stake, unregister.
 * 8. Job Creation & Management (Requester): Create, update (before selection), cancel (before selection),
 *    select provider, rescind selection, confirm completion, open dispute, reclaim escrow.
 * 9. Job Application & Execution (Provider): Apply for job, cancel application, submit result.
 * 10. Job Finalization: Timeout job, finalize job after verification timeout.
 * 11. Dispute Resolution Functions: Open dispute, admin resolution (placeholder).
 * 12. Utility/View Functions: Get contract state, get provider info, get job info, list jobs (placeholders), get balances.
 */

/**
 * @dev Function Summary (26 non-view functions + 14 view functions = 40 functions total):
 *
 * Admin/Owner Functions (7):
 * - setProtocolFeeRecipient: Set address receiving protocol fees.
 * - setProtocolFeePercentage: Set percentage fee taken by protocol.
 * - setMinimumProviderStake: Set min ETH stake required for providers.
 * - setJobVerificationPeriod: Set time requester has to verify results.
 * - setUnstakingPeriod: Set cooldown period for provider stake withdrawal.
 * - withdrawProtocolFeesRefactored: Owner withdraws accumulated protocol fees.
 * - adminResolveDispute: Owner makes a final decision on a dispute (placeholder).
 *
 * Provider Management (6):
 * - registerProviderRefactored: Register as a compute provider (requires stake).
 * - updateProviderCapabilities: Update description of services/hardware.
 * - stakeProviderRefactored: Add more ETH to provider stake.
 * - unstakeProviderRefactored: Initiate withdrawal of stake (starts cooldown).
 * - withdrawUnstakedAmountRefactored: Withdraw stake after unstaking period.
 * - unregisterProvider: Gracefully exit as a provider.
 *
 * Job Creation & Management (Requester) (8):
 * - createJobRequest: Create a new compute job request (requires escrow payment).
 * - updateJobRequest: Update job details before a provider is selected.
 * - cancelJobRequest: Cancel a job request before a provider is selected.
 * - selectApplicant: Select a provider who applied for the job.
 * - rescindProviderSelection: Cancel selection if provider fails to make progress.
 * - confirmJobCompletion: Confirm the provider successfully completed the job (triggers payment).
 * - openDispute: Open a dispute regarding job completion or payment.
 * - reclaimEscrowIfCancelled: Requester reclaims escrow if job is cancelled/timed out before selection.
 *
 * Job Application & Execution (Provider) (3):
 * - applyForJob: Provider applies for an open job request.
 * - cancelJobApplication: Provider cancels their application for a job.
 * - submitComputationResult: Provider submits proof/link to the result of the computation.
 *
 * Job Finalization (2):
 * - timeoutJob: Anyone can call to mark a job as TIMED_OUT if deadlines are missed (e.g., provider deadline). Handles escrow refund if applicable.
 * - finalizeJobAfterVerificationTimeout: Anyone can call to finalize payment to provider if requester misses verification deadline without dispute.
 *
 * Utility/View Functions (14):
 * - getProvider: Get details of a registered provider.
 * - getProviderStakeRefactored: Get current stake details of a provider.
 * - getJob: Get details of a specific job.
 * - getJobState: Get the current state of a job.
 * - getJobApplicants: Get list of providers who applied for a job.
 * - listOpenJobs: Get list of job IDs in OPEN state (placeholder - use off-chain indexer).
 * - listProviderJobs: Get list of job IDs assigned to a provider (placeholder - use off-chain indexer).
 * - listRequesterJobs: Get list of job IDs created by a requester (placeholder - use off-chain indexer).
 * - getProtocolFeePercentage: Get protocol fee percentage.
 * - getMinimumProviderStake: Get minimum provider stake.
 * - getJobVerificationPeriod: Get job verification period.
 * - getUnstakingPeriod: Get unstaking cooldown period.
 * - getAccruedProtocolFeeBalance: Get the current balance of accumulated protocol fees.
 * - getRequesterEscrowBalance: Get the total ETH currently escrowed by a requester for their active jobs.
 */

// Custom error codes for clarity and gas efficiency (ERC-3643 style)
error NotOwner(); // Covered by Ownable
error Paused(); // Covered by Pausable
error NotPaused(); // Covered by Pausable
error ReentrantCall(); // Covered by ReentrancyGuard
error ProviderNotRegistered();
error JobDoesNotExist();
error JobNotInState();
error NotJobRequester();
error NotJobProvider();
error NotJobParticipant();
error InvalidStakeAmount();
error InsufficientStake();
error StakeWithdrawalLocked();
error NoUnstakePending();
error UnstakePeriodNotElapsed();
error JobAlreadyHasProvider();
error NotJobApplicant();
error JobDeadlineMissed();
error VerificationPeriodStillActive();
error DisputePeriodStillActive(); // Should not be possible if state machine is correct, but safety check
error DisputePeriodElapsed(); // Currently not used for timeouts, but useful for dispute system
error DisputeAlreadyOpen();
error JobNotCompleted(); // Not strictly needed with state checks
error FeePercentageTooHigh();
error ZeroAddressNotAllowed();
error InvalidJobUpdate();
error JobStillActive(); // Not strictly needed with state checks
error UnregisterFailedActiveStakeOrPending(); // Renamed from UnregisterFailedActiveJobs to reflect stake check

contract DecentralizedAIComputeMarketplace is Ownable, Pausable, ReentrancyGuard {
    using SafeMath for uint256;

    // --- State Variables ---
    uint256 public protocolFeePercentage; // e.g., 5 = 5%
    address payable public protocolFeeRecipient;
    uint256 public minimumProviderStake; // Minimum ETH required to be a provider
    uint256 public jobVerificationPeriod; // Time (seconds) for requester to verify result
    uint256 public unstakingPeriod; // Time (seconds) after unstake request before withdrawal

    uint256 private nextJobId; // Counter for unique job IDs

    uint256 public totalProtocolFeesAccrued; // Tracks fees ready for owner withdrawal

    // --- Enums ---
    enum JobState {
        OPEN,               // Job is available for providers to apply
        APPLICATIONS_CLOSED, // Optional intermediate state
        ASSIGNED,           // Provider selected, waiting for provider to act (e.g., confirm start or submit result)
        COMPUTING,          // Provider is working on the job (optional state, could be merged with ASSIGNED)
        VERIFICATION_PENDING, // Provider submitted result, requester needs to verify within time limit
        COMPLETED,          // Job successfully completed, payment released to provider
        CANCELLED,          // Job cancelled by requester before assignment
        TIMED_OUT,          // Job timed out due to missed deadline (e.g., provider failed to submit, requester failed to verify/dispute)
        DISPUTE_OPEN,       // Job is under dispute resolution
        FAILED              // Job failed (e.g., dispute resolved against provider, or other failure)
    }

    // --- Structs ---
    struct Provider {
        address payable providerAddress;
        string capabilities; // e.g., "GPU: NVIDIA V100, RAM: 128GB"
        bool isRegistered;
        uint256 registeredTimestamp;
        uint256 totalJobsCompleted;
        uint256 totalReputationPoints; // Basic reputation, could be expanded
    }

    struct Job {
        uint256 jobId;
        address payable requester;
        address payable provider; // Assigned provider address (0x0 if none)
        string description;     // Task description (e.g., "Train CNN on ImageNet")
        string inputDataLink;   // IPFS hash or URL for input data
        string outputDataLink;  // IPFS hash or URL for result data
        uint256 budget;         // ETH amount offered for the job
        JobState state;
        uint256 creationTimestamp;
        uint256 assignmentTimestamp; // When provider was assigned
        uint256 resultSubmissionTimestamp; // When provider submitted result
        uint256 disputeOpenTimestamp; // When dispute was opened
        uint256 deadline;       // Deadline for provider to complete the job (timestamp). 0 for no deadline.
        // Applicants list is in a separate mapping for gas efficiency
    }

    struct StakeInfo {
        uint256 activeStake;
        uint256 pendingWithdrawal;
        uint256 withdrawUnlockTime; // Timestamp when pendingWithdrawal can be withdrawn (0 if none)
     }

    // --- Mappings ---
    mapping(address => Provider) public providers;
    mapping(address => StakeInfo) public providerStakes; // Using Refactored struct but simpler name
    mapping(uint256 => Job) public jobs;
    mapping(address => uint256) public requesterEscrows; // ETH held for jobs, tracked per requester
    mapping(uint256 => address[]) private jobApplicants; // Addresses of providers who applied for a job

    // --- Events ---
    event ProtocolFeeRecipientUpdated(address indexed newRecipient);
    event ProtocolFeePercentageUpdated(uint256 newPercentage);
    event MinimumProviderStakeUpdated(uint256 newStake);
    event JobVerificationPeriodUpdated(uint256 newPeriod);
    event UnstakingPeriodUpdated(uint256 newPeriod);
    event ProtocolFeesWithdrawn(address indexed recipient, uint256 amount);

    event ProviderRegistered(address indexed provider, string capabilities);
    event ProviderCapabilitiesUpdated(address indexed provider, string capabilities);
    event ProviderStaked(address indexed provider, uint256 amount);
    event ProviderUnstakeRequested(address indexed provider, uint256 amount, uint256 unlockTime);
    event ProviderStakeWithdrawn(address indexed provider, uint256 amount);
    event ProviderUnregistered(address indexed provider);

    event JobCreated(uint256 indexed jobId, address indexed requester, uint256 budget, string description);
    event JobUpdated(uint256 indexed jobId, string description, string inputDataLink, uint256 deadline);
    event JobCancelled(uint256 indexed jobId, address indexed requester);
    event JobApplicantApplied(uint256 indexed jobId, address indexed provider);
    event JobApplicantCancelled(uint256 indexed jobId, address indexed provider);
    event ProviderSelected(uint256 indexed jobId, address indexed requester, address indexed provider);
    event ProviderSelectionRescinded(uint256 indexed jobId, address indexed requester, address indexed provider);
    event ComputationResultSubmitted(uint256 indexed jobId, address indexed provider, string outputDataLink);
    event JobCompleted(uint256 indexed jobId, address indexed requester, address indexed provider, uint256 paymentAmount);
    event JobTimedOut(uint256 indexed jobId, JobState fromState, JobState toState);
    event JobFailed(uint256 indexed jobId, JobState fromState, string reason);

    event DisputeOpened(uint256 indexed jobId, address indexed party, string reason);
    event DisputeResolved(uint256 indexed jobId, JobState finalState, string resolutionDetails);

    event EscrowRefunded(uint256 indexed jobId, address indexed requester, uint256 amount);


    // --- Modifiers ---
    modifier onlyProvider(address _provider) {
        if (!providers[_provider].isRegistered) revert ProviderNotRegistered();
        _;
    }

    modifier onlyJobRequester(uint256 _jobId) {
        if (jobs[_jobId].requester == address(0)) revert JobDoesNotExist(); // Check existence implicitly
        if (jobs[_jobId].requester != msg.sender) revert NotJobRequester();
        _;
    }

    modifier onlyJobProvider(uint256 _jobId) {
        if (jobs[_jobId].requester == address(0)) revert JobDoesNotExist(); // Check existence implicitly
        if (jobs[_jobId].provider != msg.sender) revert NotJobProvider();
        _;
    }

    modifier onlyJobParticipant(uint256 _jobId) {
        if (jobs[_jobId].requester == address(0)) revert JobDoesNotExist(); // Check existence implicitly
        if (jobs[_jobId].requester != msg.sender && jobs[_jobId].provider != msg.sender) revert NotJobParticipant();
        _;
    }

    modifier jobExists(uint256 _jobId) {
        if (jobs[_jobId].requester == address(0)) revert JobDoesNotExist(); // Requester address is 0x0 for uninitialized struct
        _;
    }

    modifier jobInState(uint256 _jobId, JobState _expectedState) {
        if (jobs[_jobId].state != _expectedState) revert JobNotInState();
        _;
    }

    // --- Constructor ---
    constructor(address payable _protocolFeeRecipient, uint256 _protocolFeePercentage, uint256 _minimumProviderStake, uint256 _jobVerificationPeriod, uint256 _unstakingPeriod) Ownable(msg.sender) {
        if (_protocolFeeRecipient == address(0)) revert ZeroAddressNotAllowed();
        if (_protocolFeePercentage > 100) revert FeePercentageTooHigh();
        protocolFeeRecipient = _protocolFeeRecipient;
        protocolFeePercentage = _protocolFeePercentage;
        minimumProviderStake = _minimumProviderStake;
        jobVerificationPeriod = _jobVerificationPeriod;
        unstakingPeriod = _unstakingPeriod;
        nextJobId = 1;
        totalProtocolFeesAccrued = 0; // Initialize accrued fees
    }

    // --- Admin Functions (Ownable) ---

    /**
     * @dev Sets the address that receives protocol fees.
     * @param _newRecipient The new recipient address.
     */
    function setProtocolFeeRecipient(address payable _newRecipient) external onlyOwner {
        if (_newRecipient == address(0)) revert ZeroAddressNotAllowed();
        protocolFeeRecipient = _newRecipient;
        emit ProtocolFeeRecipientUpdated(_newRecipient);
    }

    /**
     * @dev Sets the percentage of job budget taken as protocol fee.
     * @param _newPercentage The new fee percentage (0-100).
     */
    function setProtocolFeePercentage(uint256 _newPercentage) external onlyOwner {
        if (_newPercentage > 100) revert FeePercentageTooHigh();
        protocolFeePercentage = _newPercentage;
        emit ProtocolFeePercentageUpdated(_newPercentage);
    }

    /**
     * @dev Sets the minimum ETH stake required for providers.
     * @param _newStake The new minimum stake amount.
     */
    function setMinimumProviderStake(uint256 _newStake) external onlyOwner {
        minimumProviderStake = _newStake;
        emit MinimumProviderStakeUpdated(_newStake);
    }

    /**
     * @dev Sets the time period a requester has to verify a submitted result.
     * @param _newPeriod The new verification period in seconds.
     */
    function setJobVerificationPeriod(uint256 _newPeriod) external onlyOwner {
        jobVerificationPeriod = _newPeriod;
        emit JobVerificationPeriodUpdated(_newPeriod);
    }

    /**
     * @dev Sets the cooldown period after a provider requests to unstake.
     * @param _newPeriod The new unstaking period in seconds.
     */
    function setUnstakingPeriod(uint256 _newPeriod) external onlyOwner {
        unstakingPeriod = _newPeriod;
        emit UnstakingPeriodUpdated(_newPeriod);
    }

    /**
     * @dev Allows the owner to withdraw accumulated protocol fees.
     */
    function withdrawProtocolFeesRefactored() external onlyOwner nonReentrant {
        uint256 balanceToWithdraw = totalProtocolFeesAccrued;
        if (balanceToWithdraw == 0) return;

        totalProtocolFeesAccrued = 0; // Reset before sending

        (bool success,) = protocolFeeRecipient.call{value: balanceToWithdraw}("");
        require(success, "Protocol fee withdrawal failed");

        emit ProtocolFeesWithdrawn(protocolFeeRecipient, balanceToWithdraw);
    }

    /**
     * @dev Resolves a dispute. Intended to be called by an admin or a trusted oracle.
     *      NOTE: This is a basic placeholder. A real decentralized dispute system
     *      would be much more complex (e.g., Schelling game, voting, Kleros integration).
     * @param _jobId The ID of the job in dispute.
     * @param _resolveInFavorOfRequester True if resolving in favor of the requester, false for provider.
     * @param _resolutionDetails Details about the resolution.
     */
    function adminResolveDispute(uint256 _jobId, bool _resolveInFavorOfRequester, string calldata _resolutionDetails)
        external
        onlyOwner // Or replace with a trusted oracle/DAO check
        jobExists(_jobId)
        jobInState(_jobId, JobState.DISPUTE_OPEN)
        nonReentrant
    {
        Job storage job = jobs[_jobId];

        // Ensure requester escrow balance is sufficient to cover the job budget
        // This check is important because `requesterEscrows` tracks the sum for a requester,
        // and the budget for this specific job needs to be accounted for.
        // Alternatively, escrow could be moved to a job-specific balance on creation.
        // For this structure, we assume the total `requesterEscrows[job.requester]` >= `job.budget`.
        // It was decremented on `confirmJobCompletion` or `finalizeJobAfterVerificationTimeout`,
        // so if dispute happens from VERIFICATION_PENDING, it might still be in escrow.
        // If dispute happens from earlier states, it's definitely in escrow.
        // Need to ensure we only subtract from `requesterEscrows` once per job budget.

        if (_resolveInFavorOfRequester) {
            // Refund requester
            uint256 refundAmount = job.budget;

            // Refund logic: If job state was VERIFICATION_PENDING or earlier when dispute opened,
            // the budget is still in requesterEscrows or contract balance.
            // Let's assume it's still conceptually tied to the requester's escrow.
            // Check if escrow for this requester is at least the job budget before refunding.
            // A more robust system moves budget to contract balance *on job creation*
            // and decrements requesterEscrows, then this fn transfers from contract balance.
            // Let's simulate moving from escrow to contract balance conceptually on job creation for simplicity here.
            // The `requesterEscrows` mapping is primarily for tracking *total* ETH a requester has pending in jobs.
            // The actual ETH is in the contract balance.

            // Check if the job budget hasn't been paid out already (e.g., confirmed or finalized by timeout)
            // JobState.COMPLETED means it was paid. JobState.FAILED means already refunded via this function.
            if (job.state == JobState.COMPLETED || job.state == JobState.FAILED) revert("Job budget already processed");

            // Deduct from requester's tracked escrow (assuming it was added on creation)
            requesterEscrows[job.requester] = requesterEscrows[job.requester].sub(refundAmount);

            (bool success,) = job.requester.call{value: refundAmount}("");
            require(success, "Refund to requester failed");

            job.state = JobState.FAILED; // Job failed from provider's perspective
             emit JobFailed(_jobId, JobState.DISPUTE_OPEN, "Resolved in favor of requester");

        } else { // Resolve in favor of provider
            // Pay provider
            uint256 paymentAmount = job.budget;
            uint256 feeAmount = paymentAmount.mul(protocolFeePercentage).div(100);
            uint256 providerAmount = paymentAmount.sub(feeAmount);

            // Check if the job budget hasn't been paid out already
            if (job.state == JobState.COMPLETED || job.state == JobState.FAILED) revert("Job budget already processed");

             // Deduct from requester's tracked escrow (assuming it was added on creation)
            requesterEscrows[job.requester] = requesterEscrows[job.requester].sub(job.budget); // Subtract full budget

             (bool successProvider,) = job.provider.call{value: providerAmount}("");
            require(successProvider, "Payment to provider failed");

            totalProtocolFeesAccrued = totalProtocolFeesAccrued.add(feeAmount); // Accrue fee

            job.state = JobState.COMPLETED; // Job completed from provider's perspective
             emit JobCompleted(_jobId, job.requester, job.provider, providerAmount);

        }

         emit DisputeResolved(_jobId, job.state, _resolutionDetails);
    }


    // --- Provider Management Functions ---

    /**
     * @dev Registers the caller as a compute provider. Requires staking a minimum amount.
     * @param _capabilities Description of the provider's compute capabilities.
     */
    function registerProviderRefactored(string calldata _capabilities) external payable whenNotPaused nonReentrant {
        if (providers[msg.sender].isRegistered) revert("Provider already registered");
        if (msg.value < minimumProviderStake) revert InsufficientStake();
        if (msg.sender == address(0)) revert ZeroAddressNotAllowed();

        providers[msg.sender] = Provider({
            providerAddress: payable(msg.sender),
            capabilities: _capabilities,
            isRegistered: true,
            registeredTimestamp: block.timestamp,
            totalJobsCompleted: 0,
            totalReputationPoints: 0
        });

        providerStakes[msg.sender].activeStake = providerStakes[msg.sender].activeStake.add(msg.value);

        emit ProviderRegistered(msg.sender, _capabilities);
        emit ProviderStaked(msg.sender, msg.value);
    }

    /**
     * @dev Updates the capabilities description for a registered provider.
     * @param _capabilities The new capabilities description.
     */
    function updateProviderCapabilities(string calldata _capabilities) external whenNotPaused onlyProvider(msg.sender) {
        providers[msg.sender].capabilities = _capabilities;
        emit ProviderCapabilitiesUpdated(msg.sender, _capabilities);
    }

    /**
     * @dev Adds more ETH to the provider's active stake.
     */
    function stakeProviderRefactored() external payable whenNotPaused nonReentrant onlyProvider(msg.sender) {
        if (msg.value == 0) revert InvalidStakeAmount();
        providerStakes[msg.sender].activeStake = providerStakes[msg.sender].activeStake.add(msg.value);
        emit ProviderStaked(msg.sender, msg.value);
    }

    /**
     * @dev Initiates the process of unstaking some or all of the provider's active stake.
     *      Funds become available after the unstaking period.
     * @param _amount The amount to unstake.
     */
    function unstakeProviderRefactored(uint256 _amount) external whenNotPaused nonReentrant onlyProvider(msg.sender) {
        StakeInfo storage stakeInfo = providerStakes[msg.sender];

        // Check if there's already a pending unstake
        if (stakeInfo.pendingWithdrawal > 0) revert StakeWithdrawalLocked();

        // Ensure provider maintains minimum stake if not unstaking everything
        if (stakeInfo.activeStake.sub(_amount) < minimumProviderStake && stakeInfo.activeStake.sub(_amount) != 0) {
             revert InsufficientStake(); // Cannot go below minimum unless unstaking everything
        }

        if (_amount == 0 || stakeInfo.activeStake < _amount) revert InvalidStakeAmount();

        stakeInfo.activeStake = stakeInfo.activeStake.sub(_amount);
        stakeInfo.pendingWithdrawal = _amount;
        stakeInfo.withdrawUnlockTime = block.timestamp.add(unstakingPeriod);

        emit ProviderUnstakeRequested(msg.sender, _amount, stakeInfo.withdrawUnlockTime);
    }

     /**
      * @dev Withdraws the unstaked amount after the unstaking period has elapsed.
      *      Can only be called if a pending unstake request exists and the time is up.
      */
     function withdrawUnstakedAmountRefactored() external whenNotPaused nonReentrant onlyProvider(msg.sender) {
        StakeInfo storage stakeInfo = providerStakes[msg.sender];

         // Check if there's a pending unstake amount
         if (stakeInfo.pendingWithdrawal == 0) revert NoUnstakePending();

         // Check if the unstaking period has elapsed
         if (block.timestamp < stakeInfo.withdrawUnlockTime) revert UnstakePeriodNotElapsed();

         uint256 amountToWithdraw = stakeInfo.pendingWithdrawal;
         stakeInfo.pendingWithdrawal = 0;
         stakeInfo.withdrawUnlockTime = 0; // Reset

         (bool success,) = payable(msg.sender).call{value: amountToWithdraw}("");
         require(success, "Stake withdrawal failed");

         emit ProviderStakeWithdrawn(msg.sender, amountToWithdraw);
     }

    /**
     * @dev Allows a provider to unregister. Requires no active stake or pending unstakes.
     *      Does NOT withdraw stake automatically - unstake/withdraw must happen separately.
     *      NOTE: Does not currently check for active jobs assigned to the provider. A robust
     *      contract would need to prevent unregistering with active jobs or handle them.
     */
    function unregisterProvider() external whenNotPaused nonReentrant onlyProvider(msg.sender) {
        // Check for active stake or pending unstake
        if (providerStakes[msg.sender].activeStake > 0 || providerStakes[msg.sender].pendingWithdrawal > 0) {
             revert UnregisterFailedActiveStakeOrPending();
        }

        // TODO: Add check for active jobs assigned to this provider. Omitted for brevity.
        // This would likely require iterating a list/mapping of provider's job IDs.

        providers[msg.sender].isRegistered = false;
        // Could also clear capabilities etc. to save a tiny bit of space, but bool isRegistered is sufficient.

        emit ProviderUnregistered(msg.sender);
    }


    // --- Job Creation & Management (Requester) ---

    /**
     * @dev Creates a new job request. Requires sending the full budget as escrow.
     * @param _description Description of the AI task.
     * @param _inputDataLink Link to input data (IPFS hash, URL).
     * @param _deadline Deadline for the provider to complete the job (timestamp). 0 for no deadline.
     */
    function createJobRequest(
        string calldata _description,
        string calldata _inputDataLink,
        uint256 _deadline
    ) external payable whenNotPaused nonReentrant {
        if (msg.value == 0) revert InvalidStakeAmount(); // Budget cannot be zero
        if (msg.sender == address(0)) revert ZeroAddressNotAllowed();

        uint256 currentJobId = nextJobId;
        nextJobId++;

        jobs[currentJobId] = Job({
            jobId: currentJobId,
            requester: payable(msg.sender),
            provider: payable(address(0)), // No provider assigned yet
            description: _description,
            inputDataLink: _inputDataLink,
            outputDataLink: "", // No result yet
            budget: msg.value,
            state: JobState.OPEN,
            creationTimestamp: block.timestamp,
            assignmentTimestamp: 0,
            resultSubmissionTimestamp: 0,
            disputeOpenTimestamp: 0,
            deadline: _deadline
             // applicants list is in separate mapping
        });

        // Escrow the payment. We use a mapping to track per-requester escrow.
        // The ETH is now in the contract balance, but tracked against the requester.
        requesterEscrows[msg.sender] = requesterEscrows[msg.sender].add(msg.value);

        emit JobCreated(currentJobId, msg.sender, msg.value, _description);
    }

     /**
      * @dev Allows the requester to update job details while in the OPEN state.
      * @param _jobId The ID of the job to update.
      * @param _description New description.
      * @param _inputDataLink New input data link.
      * @param _deadline New deadline (0 for no deadline).
      */
    function updateJobRequest(
        uint256 _jobId,
        string calldata _description,
        string calldata _inputDataLink,
        uint256 _deadline
    ) external whenNotPaused jobExists(_jobId) onlyJobRequester(_jobId) jobInState(_jobId, JobState.OPEN) {
         jobs[_jobId].description = _description;
         jobs[_jobId].inputDataLink = _inputDataLink;
         jobs[_jobId].deadline = _deadline;

         emit JobUpdated(_jobId, _description, _inputDataLink, _deadline);
    }

    /**
     * @dev Allows the requester to cancel a job request if no provider has been selected yet.
     *      Refunds the escrowed ETH.
     * @param _jobId The ID of the job to cancel.
     */
    function cancelJobRequest(uint256 _jobId)
        external
        whenNotPaused
        jobExists(_jobId)
        onlyJobRequester(_jobId)
        jobInState(_jobId, JobState.OPEN)
        nonReentrant
    {
        Job storage job = jobs[_jobId];
        uint256 refundAmount = job.budget;

        // Decrease requester's total escrow tracking
        requesterEscrows[msg.sender] = requesterEscrows[msg.sender].sub(refundAmount);

        // Refund the ETH directly to the requester
        (bool success,) = job.requester.call{value: refundAmount}("");
        require(success, "Escrow refund failed");

        job.state = JobState.CANCELLED;
        emit JobCancelled(_jobId, msg.sender);

        // Clear applicants list for the cancelled job
        delete jobApplicants[_jobId];
    }

    /**
     * @dev Allows the requester to select a provider from the applicants list.
     *      Transitions job to ASSIGNED state.
     * @param _jobId The ID of the job.
     * @param _provider The address of the provider to select.
     */
    function selectApplicant(uint256 _jobId, address _provider)
        external
        whenNotPaused
        jobExists(_jobId)
        onlyJobRequester(_jobId)
        jobInState(_jobId, JobState.OPEN) // Job must be open for applications
        onlyProvider(_provider) // Selected address must be a registered provider
    {
        Job storage job = jobs[_jobId];

        // Optional: Check if the selected provider actually applied.
        bool found = false;
        address[] storage applicants = jobApplicants[_jobId];
        for (uint i = 0; i < applicants.length; i++) {
            if (applicants[i] == _provider) {
                found = true;
                break;
            }
        }
        if (!found) revert NotJobApplicant(); // Provider didn't apply

        job.provider = payable(_provider);
        job.assignmentTimestamp = block.timestamp; // Record assignment time
        job.state = JobState.ASSIGNED; // Provider is now assigned

        // Clear applicants list once someone is selected
        delete jobApplicants[_jobId];

        emit ProviderSelected(_jobId, msg.sender, _provider);
    }

    /**
     * @dev Allows the requester to rescind the provider selection if the provider
     *      fails to transition the job out of the ASSIGNED state within a reasonable time (e.g., misses deadline if set).
     *      Refunds requester escrow, job goes to TIMED_OUT.
     *      NOTE: This function does not automatically check a timeout period in ASSIGNED state.
     *      The requester calls this manually. An automatic timeout can be triggered by `timeoutJob`.
     * @param _jobId The ID of the job.
     */
    function rescindProviderSelection(uint256 _jobId)
        external
        whenNotPaused
        jobExists(_jobId)
        onlyJobRequester(_jobId)
        jobInState(_jobId, JobState.ASSIGNED) // Can only rescind from ASSIGNED state
        nonReentrant
    {
        Job storage job = jobs[_jobId];

        uint256 refundAmount = job.budget;

        // Decrease requester's total escrow tracking
        requesterEscrows[msg.sender] = requesterEscrows[msg.sender].sub(refundAmount);

        // Refund the ETH directly to the requester
        (bool success,) = job.requester.call{value: refundAmount}("");
        require(success, "Escrow refund failed on rescind");

        // Job goes to TIMED_OUT state
        job.state = JobState.TIMED_OUT;
        // Provider remains recorded in the Job struct but the job state indicates failure/timeout.

        emit ProviderSelectionRescinded(_jobId, msg.sender, job.provider);
        emit JobTimedOut(_jobId, JobState.ASSIGNED, JobState.TIMED_OUT); // Indicate timeout from ASSIGNED state
    }


    /**
     * @dev Confirms successful job completion by the requester.
     *      Transitions job to COMPLETED state and triggers payment to provider.
     * @param _jobId The ID of the job.
     */
    function confirmJobCompletion(uint256 _jobId)
        external
        whenNotPaused
        jobExists(_jobId)
        onlyJobRequester(_jobId)
        jobInState(_jobId, JobState.VERIFICATION_PENDING)
        nonReentrant
    {
        Job storage job = jobs[_jobId];

        // Check if verification period is still active (optional, can allow early confirmation)
        // require(block.timestamp < job.resultSubmissionTimestamp + jobVerificationPeriod, VerificationPeriodElapsed());

        // Check if a dispute is open
        if (job.state == JobState.DISPUTE_OPEN) revert DisputeAlreadyOpen(); // Safety check

        // Calculate fees and amounts
        uint256 paymentAmount = job.budget;
        uint256 feeAmount = paymentAmount.mul(protocolFeePercentage).div(100);
        uint256 providerAmount = paymentAmount.sub(feeAmount);

        // Decrease requester's total escrow tracking by the job budget (which is now being paid out)
        // This should only happen ONCE when the budget is distributed (either to provider or refunded).
        // Since this is confirmation -> payment, we subtract the budget here.
        requesterEscrows[msg.sender] = requesterEscrows[msg.sender].sub(job.budget);

        // Accrue protocol fee
        totalProtocolFeesAccrued = totalProtocolFeesAccrued.add(feeAmount);

        // Pay the provider
        (bool successProvider,) = job.provider.call{value: providerAmount}("");
        require(successProvider, "Payment to provider failed");

        job.state = JobState.COMPLETED;

        // Update provider stats (basic reputation)
        if (providers[job.provider].isRegistered) { // Only update if provider is still registered
             providers[job.provider].totalJobsCompleted = providers[job.provider].totalJobsCompleted.add(1);
             // Basic positive reputation boost
             providers[job.provider].totalReputationPoints = providers[job.provider].totalReputationPoints.add(2); // Bigger boost for confirmed completion
        }

        emit JobCompleted(_jobId, msg.sender, job.provider, providerAmount);
    }

    /**
     * @dev Allows either the requester or provider to open a dispute.
     *      Transitions job to DISPUTE_OPEN state.
     * @param _jobId The ID of the job.
     * @param _reason Brief reason for the dispute.
     */
    function openDispute(uint256 _jobId, string calldata _reason)
        external
        whenNotPaused
        jobExists(_jobId)
        onlyJobParticipant(_jobId)
        nonReentrant
    {
        Job storage job = jobs[_jobId];

        // Allow dispute from states where work is expected or verification is pending
        if (job.state != JobState.ASSIGNED && // Provider assigned but not making progress?
            job.state != JobState.COMPUTING && // Provider claims working, requester disagrees?
            job.state != JobState.VERIFICATION_PENDING) { // Requester disagrees with result, or Provider claims result is fine
             revert JobNotInState();
        }

        // Prevent opening dispute if one is already open
        if (job.state == JobState.DISPUTE_OPEN) revert DisputeAlreadyOpen();

        job.state = JobState.DISPUTE_OPEN;
        job.disputeOpenTimestamp = block.timestamp;

        emit DisputeOpened(_jobId, msg.sender, _reason);

        // NOTE: Actual dispute resolution logic (voting, evidence, etc.) is complex
        // and likely happens off-chain or involves another protocol (like Kleros).
        // The `adminResolveDispute` is a simple placeholder for state transition after resolution.
    }

    /**
     * @dev Allows the requester to reclaim their escrowed funds if the job
     *      was cancelled or timed out BEFORE a provider was selected/assigned.
     *      This function performs the actual ETH transfer.
     * @param _jobId The ID of the job.
     */
    function reclaimEscrowIfCancelled(uint256 _jobId)
         external
         whenNotPaused
         jobExists(_jobId)
         onlyJobRequester(_jobId)
         nonReentrant
    {
         Job storage job = jobs[_jobId];

         // Only allow if the job is in CANCELLED or TIMED_OUT state AND had no provider assigned
         if (job.provider != address(0)) revert JobAlreadyHasProvider();
         if (job.state != JobState.CANCELLED && job.state != JobState.TIMED_OUT) revert JobNotInState();

         // Check if escrow for this job budget is still tracked against the requester.
         // This prevents double-refunds if the escrow was somehow already paid out.
         // This relies on requesterEscrows accurately tracking amounts that *can* be refunded.
         // A more robust system might use a job-specific escrow balance.
         uint256 refundAmount = job.budget;

         // Decrease requester's total escrow tracking
         // Ensure the requester has enough escrow tracked to cover this job's budget before subtracting
         if (requesterEscrows[msg.sender] < refundAmount) revert("Insufficient tracked escrow for refund");
         requesterEscrows[msg.sender] = requesterEscrows[msg.sender].sub(refundAmount);


         // Refund the ETH directly to the requester
         (bool success,) = job.requester.call{value: refundAmount}("");
         require(success, "Escrow refund failed");

         // Could transition to a final state like 'REFUNDED' if needed
         // Job state remains CANCELLED or TIMED_OUT, which implies refund if provider is 0x0

         emit EscrowRefunded(_jobId, job.requester, refundAmount);
    }


    // --- Job Application & Execution (Provider) ---

    /**
     * @dev Allows a registered provider to apply for an open job request.
     * @param _jobId The ID of the job to apply for.
     */
    function applyForJob(uint256 _jobId)
        external
        whenNotPaused
        jobExists(_jobId)
        onlyProvider(msg.sender)
        jobInState(_jobId, JobState.OPEN)
    {
        Job storage job = jobs[_jobId];

        // Check if provider has already applied (basic check, could be optimized for many applicants)
        address[] storage applicants = jobApplicants[_jobId];
        for (uint i = 0; i < applicants.length; i++) {
            if (applicants[i] == msg.sender) {
                revert("Provider already applied");
            }
        }

        applicants.push(msg.sender); // Add provider to applicants list

        emit JobApplicantApplied(_jobId, msg.sender);
    }

    /**
     * @dev Allows a provider to cancel their application for a job.
     * @param _jobId The ID of the job.
     */
    function cancelJobApplication(uint256 _jobId)
         external
         whenNotPaused
         jobExists(_jobId)
         onlyProvider(msg.sender)
         jobInState(_jobId, JobState.OPEN)
    {
         address[] storage applicants = jobApplicants[_jobId];
         bool found = false;
         for (uint i = 0; i < applicants.length; i++) {
             if (applicants[i] == msg.sender) {
                 // Remove by swapping with last and popping (gas efficient)
                 applicants[i] = applicants[applicants.length - 1];
                 applicants.pop();
                 found = true;
                 break;
             }
         }

         if (!found) revert NotJobApplicant(); // Provider did not apply for this job

         emit JobApplicantCancelled(_jobId, msg.sender);
    }

    /**
     * @dev Allows the assigned provider to submit the result of the computation.
     *      Transitions job to VERIFICATION_PENDING state.
     * @param _jobId The ID of the job.
     * @param _outputDataLink Link to the output data (IPFS hash, URL).
     */
    function submitComputationResult(uint256 _jobId, string calldata _outputDataLink)
        external
        whenNotPaused
        jobExists(_jobId)
        onlyJobProvider(_jobId)
    {
        Job storage job = jobs[_jobId];

        // Allow submission from ASSIGNED or COMPUTING states
        if (job.state != JobState.ASSIGNED && job.state != JobState.COMPUTING) {
             revert JobNotInState();
        }
        // Can optionally add a state transition from ASSIGNED to COMPUTING,
        // triggered by the provider when they actually start work.
        // For simplicity, submitting result moves from ASSIGNED/COMPUTING to VERIFICATION_PENDING.

        job.outputDataLink = _outputDataLink;
        job.resultSubmissionTimestamp = block.timestamp;
        job.state = JobState.VERIFICATION_PENDING;

        emit ComputationResultSubmitted(_jobId, msg.sender, _outputDataLink);
    }


    // --- Job Finalization ---

    /**
     * @dev Allows anyone to transition a job to TIMED_OUT if deadlines are missed.
     *      Applies if job is ASSIGNED or COMPUTING and job.deadline is set and passed.
     *      Also applies if job is VERIFICATION_PENDING and verification period passed without resolution.
     * @param _jobId The ID of the job.
     */
    function timeoutJob(uint256 _jobId)
         external
         whenNotPaused
         jobExists(_jobId)
         nonReentrant // Could potentially involve transfers if refunding escrow
    {
         Job storage job = jobs[_jobId];
         JobState currentState = job.state;

         bool eligibleForTimeout = false;

         // Timeout if ASSIGNED/COMPUTING and provider deadline passed (if set)
         if ((currentState == JobState.ASSIGNED || currentState == JobState.COMPUTING) &&
             job.deadline != 0 && block.timestamp > job.deadline) {
             eligibleForTimeout = true;
         }
         // Timeout if VERIFICATION_PENDING and verification period passed AND no dispute opened
         else if (currentState == JobState.VERIFICATION_PENDING &&
                  block.timestamp > job.resultSubmissionTimestamp.add(jobVerificationPeriod) &&
                  job.disputeOpenTimestamp == 0) {
             eligibleForTimeout = true;
         }
         // Could add timeout for OPEN state too, but requires a protocol-wide or job-specific open duration.

         if (!eligibleForTimeout) {
              // Revert with specific reason based on state/condition if needed
              if (currentState == JobState.VERIFICATION_PENDING) revert VerificationPeriodStillActive();
              // Add other specific reverts
              revert JobDeadlineMissed(); // Generic timeout fail
         }

         // Handle financial settlement based on state at timeout
         if (currentState == JobState.ASSIGNED || currentState == JobState.COMPUTING) {
             // Provider failed to submit result within deadline.
             // Refund requester. Potentially penalize provider stake (not implemented).
             uint256 refundAmount = job.budget;

             // Decrease requester's total escrow tracking
             if (requesterEscrows[job.requester] < refundAmount) revert("Insufficient tracked escrow for refund on provider timeout"); // Safety check
             requesterEscrows[job.requester] = requesterEscrows[job.requester].sub(refundAmount);

             // Refund the ETH directly to the requester
             (bool success,) = job.requester.call{value: refundAmount}("");
             require(success, "Escrow refund failed on provider timeout");

             // Could add provider stake slashing here
             if (providers[job.provider].isRegistered) {
                  // Basic negative reputation
                  providers[job.provider].totalReputationPoints = providers[job.provider].totalReputationPoints.sub(1, "Reputation cannot go below zero"); // Safe subtraction
             }

             emit EscrowRefunded(_jobId, job.requester, refundAmount);

         } else if (currentState == JobState.VERIFICATION_PENDING) {
             // Requester failed to confirm/dispute within verification period.
             // This is a successful outcome from provider's perspective (payment due).
             // This logic is handled by `finalizeJobAfterVerificationTimeout`,
             // so this `timeoutJob` function should not reach this path for VERIFICATION_PENDING state.
             // The check `block.timestamp > job.resultSubmissionTimestamp.add(jobVerificationPeriod)`
             // in the eligibleForTimeout logic means this function *could* technically
             // transition from VERIFICATION_PENDING to TIMED_OUT.
             // Let's refine: timeoutJob handles *failure* timeouts (provider deadline missed),
             // finalizeJobAfterVerificationTimeout handles *success* timeouts (requester missed deadline).
             // So, remove VERIFICATION_PENDING from `eligibleForTimeout` in THIS function.

             // Corrected `eligibleForTimeout` check:
             bool eligibleForProviderDeadlineTimeout = (currentState == JobState.ASSIGNED || currentState == JobState.COMPUTING) &&
                                                        job.deadline != 0 && block.timestamp > job.deadline;
             if (!eligibleForProviderDeadlineTimeout) {
                  revert JobDeadlineMissed(); // Or other specific timeout error
             }
             // ... rest of the ASSIGNED/COMPUTING timeout logic ...

         } else {
              // TIMED_OUT from OPEN or other unexpected state - should not happen with current logic.
              revert("Unexpected job state for timeout");
         }

         job.state = JobState.TIMED_OUT; // Job state becomes TIMED_OUT if provider missed deadline
         emit JobTimedOut(_jobId, currentState, JobState.TIMED_OUT);

    }


     /**
      * @dev Callable by anyone to finalize a job in VERIFICATION_PENDING state
      *      if the verification period has elapsed without requester action or dispute.
      *      This triggers payment to the provider.
      * @param _jobId The ID of the job.
      */
     function finalizeJobAfterVerificationTimeout(uint256 _jobId)
         external
         whenNotPaused
         jobExists(_jobId)
         jobInState(_jobId, JobState.VERIFICATION_PENDING)
         nonReentrant
     {
         Job storage job = jobs[_jobId];

         // Check if verification period has elapsed AND no dispute was opened
         if (block.timestamp < job.resultSubmissionTimestamp.add(jobVerificationPeriod)) revert VerificationPeriodStillActive();
         if (job.disputeOpenTimestamp != 0) revert DisputeAlreadyOpen(); // Should be checked by jobInState, but double check

         // Calculate fees and amounts
         uint256 paymentAmount = job.budget;
         uint256 feeAmount = paymentAmount.mul(protocolFeePercentage).div(100);
         uint256 providerAmount = paymentAmount.sub(feeAmount);

         // Decrease requester's total escrow tracking. This should only happen once.
         // Since confirmJobCompletion also subtracts, we need a flag or rely on state.
         // The state transition from VERIFICATION_PENDING to COMPLETED *only* happens here or in confirmJobCompletion.
         // So subtracting here is safe if state was VERIFICATION_PENDING.
         requesterEscrows[job.requester] = requesterEscrows[job.requester].sub(job.budget);

         // Accrue protocol fee
         totalProtocolFeesAccrued = totalProtocolFeesAccrued.add(feeAmount);

         // Pay the provider
         (bool successProvider,) = job.provider.call{value: providerAmount}("");
         require(successProvider, "Payment to provider failed after timeout");

         job.state = JobState.COMPLETED; // Job completed due to requester timeout

         // Update provider stats (basic reputation)
         if (providers[job.provider].isRegistered) { // Only update if provider is still registered
              providers[job.provider].totalJobsCompleted = providers[job.provider].totalJobsCompleted.add(1);
              // Smaller reputation boost for timeout completion? Or same? Let's give a boost.
              providers[job.provider].totalReputationPoints = providers[job.provider].totalReputationPoints.add(1);
         }

         emit JobCompleted(_jobId, job.requester, job.provider, providerAmount);
         emit JobTimedOut(_jobId, JobState.VERIFICATION_PENDING, JobState.COMPLETED); // Indicate timeout led to completion
     }


    // --- Utility/View Functions ---

    /**
     * @dev Returns the details of a registered provider.
     * @param _provider The provider's address.
     * @return Provider struct details.
     */
    function getProvider(address _provider) external view returns (Provider memory) {
        if (!providers[_provider].isRegistered) revert ProviderNotRegistered();
        return providers[_provider];
    }

     /**
      * @dev Returns the current stake amount for a provider.
      * @param _provider The provider's address.
      * @return The active stake amount, pending withdrawal amount, and withdrawal unlock timestamp.
      */
     function getProviderStakeRefactored(address _provider) external view returns (uint256 activeStake, uint256 pendingWithdrawal, uint256 withdrawUnlockTime) {
        StakeInfo memory stakeInfo = providerStakes[_provider];
        return (stakeInfo.activeStake, stakeInfo.pendingWithdrawal, stakeInfo.withdrawUnlockTime);
     }

    /**
     * @dev Returns the details of a job.
     * @param _jobId The job ID.
     * @return Job struct details.
     */
    function getJob(uint256 _jobId) external view jobExists(_jobId) returns (Job memory) {
        return jobs[_jobId];
    }

     /**
      * @dev Returns the current state of a job.
      * @param _jobId The job ID.
      * @return The job state enum.
      */
     function getJobState(uint256 _jobId) external view jobExists(_jobId) returns (JobState) {
         return jobs[_jobId].state;
     }

     /**
      * @dev Returns the list of addresses that have applied for a job.
      *      Only relevant if job state is OPEN.
      * @param _jobId The job ID.
      * @return An array of applicant addresses.
      */
     function getJobApplicants(uint256 _jobId) external view jobExists(_jobId) returns (address[] memory) {
        // Only return applicants if job is still in OPEN state
        if (jobs[_jobId].state != JobState.OPEN) {
            return new address[](0); // Return empty if state is not OPEN
        }
         return jobApplicants[_jobId];
     }


    // --- Placeholder List Functions (Use Off-Chain Indexing for Production) ---
    // Iterating mappings is not feasible on-chain for large datasets.

    /**
     * @dev Returns a list of Job IDs in the OPEN state.
     *      NOTE: Placeholder. Efficient listing requires off-chain indexing (e.g., TheGraph).
     * @return An array of open job IDs (always empty in this placeholder).
     */
    function listOpenJobs() external view returns (uint256[] memory) {
        return new uint256[](0);
    }

     /**
      * @dev Returns a list of Job IDs assigned to a provider.
      *      NOTE: Placeholder. Requires mapping(address => uint256[]) providerToJobs or off-chain indexing.
      * @param _provider The provider's address.
      * @return An array of job IDs assigned to the provider (always empty in this placeholder).
      */
     function listProviderJobs(address _provider) external view returns (uint256[] memory) {
          return new uint256[](0);
     }

     /**
      * @dev Returns a list of Job IDs created by a requester.
      *      NOTE: Placeholder. Requires mapping(address => uint256[]) requesterToJobs or off-chain indexing.
      * @param _requester The requester's address.
      * @return An array of job IDs created by the requester (always empty in this placeholder).
      */
     function listRequesterJobs(address _requester) external view returns (uint256[] memory) {
          return new uint256[](0);
     }


    // Additional View functions for parameters and balances:
    function getProtocolFeePercentage() external view returns (uint256) { return protocolFeePercentage; }
    function getMinimumProviderStake() external view returns (uint256) { return minimumProviderStake; }
    function getJobVerificationPeriod() external view returns (uint256) { return jobVerificationPeriod; }
    function getUnstakingPeriod() external view returns (uint256) { return unstakingPeriod; }
    function getAccruedProtocolFeeBalance() external view returns (uint256) {
         return totalProtocolFeesAccrued;
     }
    function getRequesterEscrowBalance(address _requester) external view returns (uint256) {
        return requesterEscrows[_requester];
    }


    // --- Inherited Functions from OpenZeppelin ---
    // - pause() external onlyOwner
    // - unpause() external onlyOwner
    // - paused() public view returns (bool)
    // - owner() public view returns (address)
    // - renounceOwnership() external onlyOwner
    // - transferOwnership(address newOwner) external onlyOwner
    // - nonReentrant modifier (used internally)

}
```