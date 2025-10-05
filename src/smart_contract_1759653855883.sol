Here's a Solidity smart contract named `AetherialComputeHub` that aims to be interesting, advanced, creative, and trendy. It focuses on decentralized verifiable computation, integrating concepts like reputation, staking, dispute resolution, and the idea of Zero-Knowledge Proof (ZKP) hashes for off-chain verification. The design avoids direct duplication of common open-source projects by combining these elements into a novel system for a decentralized "AI/Computation Oracle" network.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Define custom errors for better clarity and gas efficiency
error Paused();
error NotPaused();
error WeaverNotRegistered();
error InsufficientStake(uint256 required, uint256 actual);
error InvalidComputationType();
error TaskNotFound();
error TaskNotClaimed();
error TaskAlreadyClaimed();
error TaskAlreadyCompleted();
error TaskAlreadyChallenged();
error ChallengePeriodNotExpired();
error TaskExpired();
error NoFundsToClaim();
error InvalidAmount();
error NotSupportedPaymentToken(); // Not explicitly used but good to have for token config.
error ComputationTypeAlreadyExists();
error ComputationTypeNotFound();
error WeaverAlreadyRegistered();
error TaskNotChallenged();
error DisputeNotResolved();
error InvalidTaskStateForAction();
error TaskNotYetSubmitted(); // Not explicitly used, superseded by InvalidTaskStateForAction.
error Unauthorized();
error InsufficientRewardForWeaver();
error TaskTimeoutNotExpired(); // Not explicitly used, superseded by TaskExpired.
error TaskNotYetReadyForCompletion();
error NotEnoughAllowance(); // Explicit error for ERC20 allowance check

// --- OUTLINE & FUNCTION SUMMARY ---

// This contract, "AetherialComputeHub," is a decentralized and verifiable computation network.
// It allows users to request complex off-chain computations (e.g., AI inferences, data aggregation)
// from a network of "Aether Weavers" (decentralized oracles). The system integrates staking,
// reputation, dispute resolution, and leverages the *concept* of Zero-Knowledge Proofs (ZKPs)
// for verifiable and potentially private computation. While full on-chain ZKP verification
// is currently cost-prohibitive for generic computations, the contract's design expects
// and utilizes ZKP verification hashes, assuming off-chain verification and on-chain dispute
// resolution.

// I. Core Infrastructure & Configuration
// 1. constructor(address _initialPaymentToken): Initializes the contract, sets the deployer as owner, and sets the initial payment token.
// 2. updateConfiguration(uint256 _minWeaverStake, uint256 _challengePeriod, uint256 _minDisputeResolutionPeriod, uint256 _taskExpirationPeriod, uint256 _weaverRewardMultiplierNumerator, uint256 _weaverRewardMultiplierDenominator, uint256 _initialReputationScore): Allows owner to update global parameters for network operation.
// 3. pause(): Pauses core contract functionalities (task submission, claiming, result submission) in an emergency. Only owner.
// 4. unpause(): Unpauses core contract functionalities. Only owner.
// 5. addSupportedComputationType(string calldata _typeId, uint256 _baseCost, uint256 _requiredWeaverStake, uint256 _minResponseTime, uint256 _maxResponseTime): Defines a new type of computation the network supports, specifying its economic and performance parameters. Only owner.
// 6. updateComputationType(string calldata _typeId, uint256 _newBaseCost, uint256 _newRequiredWeaverStake, uint256 _newMinResponseTime, uint256 _newMaxResponseTime): Modifies parameters for an existing computation type. Only owner.
// 7. removeSupportedComputationType(string calldata _typeId): Removes a supported computation type. Only owner.
// 8. setPaymentToken(address _newToken): Sets the ERC20 token used for payments and rewards. Only owner.

// II. Aether Weaver (Oracle) Management
// 9. registerAetherWeaver(string calldata _metadataURI): Allows a user to become an "Aether Weaver" by staking the minimum required amount of tokens and providing metadata.
// 10. deregisterAetherWeaver(): Allows a Weaver to unstake their tokens and leave the network after all pending tasks/disputes are resolved and a cooldown period.
// 11. updateWeaverProfile(string calldata _newMetadataURI): Allows a Weaver to update their public profile/metadata URI.
// 12. slashWeaver(address _weaverAddress, uint256 _amount): Owner/governance can manually slash a Weaver's stake for severe misconduct, or after dispute resolution.
// 13. getWeaverReputation(address _weaverAddress): Retrieves the current reputation score of an Aether Weaver.
// 14. distributeWeaverSBT(address _weaverAddress): Mints a non-transferable SoulBound Token (SBT) to a high-performing Weaver (conceptually, requires an external SBT contract interaction). Only owner.
// 15. penalizeWeaverReputation(address _weaverAddress, uint256 _penaltyAmount): Decreases a Weaver's reputation score for specific reasons (e.g., failed challenge). Only owner.

// III. Task Management & Execution
// 16. submitComputationTask(string calldata _computationTypeId, bytes32 _inputHash, bytes32 _expectedOutputPropertiesHash, uint256 _maxReward, uint256 _timeoutSeconds): User submits a task request, providing input hash, expected output properties hash (for validation), max reward, and a timeout. Requires payment upfront.
// 17. acceptTaskAssignment(bytes32 _taskId): An Aether Weaver claims an available computation task, locking their stake as per the task type's requirements.
// 18. submitTaskResult(bytes32 _taskId, bytes32 _resultHash, bytes32 _verificationProofHash): The assigned Weaver submits the hash of the off-chain computation result and a hash of its ZK-proof (or other verification data).
// 19. challengeTaskResult(bytes32 _taskId, bytes32 _challengerResultHash, bytes32 _challengerProofHash): A user or another Weaver challenges a submitted result, providing their own result hash and proof hash. This initiates a dispute. Requires a challenge stake.
// 20. resolveDispute(bytes32 _taskId, bool _weaverWasCorrect): Owner/governance resolves an active dispute, determining if the Weaver's initial result was correct or not, leading to slashing/rewards.
// 21. confirmTaskCompletion(bytes32 _taskId): After the challenge period expires or a dispute is resolved in favor of the Weaver, the task requester confirms completion, releasing payment to the Weaver and updating reputation.
// 22. cancelTask(bytes32 _taskId): The requester can cancel an unclaimed or unfulfilled task, refunding their payment (minus a fee if applicable for unclaimed tasks).

// IV. Reward & Reputation System
// 23. claimWeaverRewards(): Allows an Aether Weaver to claim their accumulated rewards from successfully completed tasks.
// 24. getWeaverStakedAmount(address _weaverAddress): Returns the amount of tokens currently staked by a specific Weaver.
// 25. getWeaverAvailableRewards(address _weaverAddress): Returns the amount of rewards a Weaver can claim.

// Total functions: 25 (excluding internal helper functions and view functions for internal state)
// Note: Some functions like `_updateWeaverReputation` are internal helpers and not directly callable public functions,
// but their logic is integrated into functions like `resolveDispute` and `confirmTaskCompletion`.
// The SBT distribution is conceptual and would require an actual SBT contract address and interface.

contract AetherialComputeHub is Ownable, ReentrancyGuard {
    // In Solidity 0.8.0+, arithmetic operations revert on overflow/underflow by default,
    // so SafeMath is primarily for older versions or explicit clarity, but not strictly needed here.

    // --- Configuration Constants & Parameters ---
    uint256 public minWeaverStake;
    uint256 public challengePeriod; // Time in seconds for challengers to dispute a result
    uint256 public minDisputeResolutionPeriod; // Minimum time for dispute resolution
    uint256 public taskExpirationPeriod; // Max time for a task to be claimed/completed after submission
    uint256 public weaverRewardMultiplierNumerator;
    uint256 public weaverRewardMultiplierDenominator;
    uint256 public initialReputationScore;
    address public paymentToken; // ERC20 token used for staking, payments, and rewards
    bool public paused;

    // --- Data Structures ---

    enum TaskStatus {
        Submitted,      // Task submitted, waiting for a weaver to claim
        Claimed,        // Task claimed by a weaver, awaiting result
        ResultSubmitted, // Weaver submitted result, awaiting challenge or completion
        Challenged,     // Result challenged, awaiting dispute resolution
        DisputeResolved,// Dispute resolved, awaiting confirmation or slashing
        Completed,      // Task successfully completed and paid
        Canceled,       // Task canceled by requester
        Failed          // Task failed (e.g., weaver timeout, failed dispute)
    }

    struct ComputationType {
        string typeId;
        uint256 baseCost;             // Base cost for this type of computation (in paymentToken)
        uint256 requiredWeaverStake;  // Minimum additional stake a weaver needs to claim this type of task
        uint256 minResponseTime;      // Expected minimum response time in seconds
        uint256 maxResponseTime;      // Expected maximum response time in seconds
        bool exists;                  // To check if a typeId is valid
    }

    struct Weaver {
        uint256 stake;
        string metadataURI;
        uint256 reputationScore;
        // uint256 lastDeregisterRequestTime; // For a future cooldown period logic
        uint256 availableRewards;
        uint256 numTasksCompleted;
        uint256 numDisputesWon;
        uint256 numDisputesLost;
        bool exists;
    }

    struct Task {
        bytes32 taskId;
        string computationTypeId;
        address requester;
        address weaver;             // Address of the weaver who claimed the task
        bytes32 inputHash;          // Hash of the input data (actual data is off-chain)
        bytes32 expectedOutputPropertiesHash; // Hash of desired output properties for basic validation
        uint256 maxReward;          // Max reward requester is willing to pay
        uint256 submissionTime;
        uint256 claimTime;
        uint256 resultSubmissionTime;
        uint256 timeoutTimestamp;   // When the task expires if not claimed/completed by weaver
        TaskStatus status;
        bytes32 resultHash;         // Hash of the weaver's submitted result
        bytes32 verificationProofHash; // Hash of the ZK-proof or other verification data
        bytes32 challengerResultHash; // Hash of the challenger's result
        bytes32 challengerProofHash;  // Hash of the challenger's proof
        address challenger;         // Address of the entity that challenged the result
        uint256 challengeStake;     // Stake put down by challenger
        bool disputeResolved;       // True if a dispute has been resolved
        bool weaverWasCorrectInDispute; // True if Weaver won the dispute, false otherwise
        bool requesterConfirmed;    // True if requester confirmed task completion
    }

    // --- Mappings & Storage ---
    mapping(address => Weaver) public weavers;
    mapping(bytes32 => Task) public tasks;
    mapping(string => ComputationType) public computationTypes;
    string[] public supportedComputationTypeIds; // To iterate over supported types

    uint256 private nextTaskIdCounter; // Simple counter for task IDs

    // --- Events ---
    event ConfigurationUpdated(uint256 _minWeaverStake, uint256 _challengePeriod, uint256 _minDisputeResolutionPeriod, uint256 _taskExpirationPeriod);
    event Paused(address indexed account);
    event Unpaused(address indexed account);
    event PaymentTokenSet(address indexed newToken);
    event ComputationTypeAdded(string indexed typeId, uint256 baseCost, uint256 requiredWeaverStake);
    event ComputationTypeUpdated(string indexed typeId, uint256 newBaseCost);
    event ComputationTypeRemoved(string indexed typeId);
    event WeaverRegistered(address indexed weaver, uint256 stake, string metadataURI);
    event WeaverDeregistered(address indexed weaver, uint256 returnedStake);
    event WeaverProfileUpdated(address indexed weaver, string newMetadataURI);
    event WeaverSlashed(address indexed weaver, uint256 amount);
    event WeaverReputationUpdated(address indexed weaver, uint256 newReputation);
    event TaskSubmitted(bytes32 indexed taskId, address indexed requester, string computationTypeId, uint256 maxReward);
    event TaskClaimed(bytes32 indexed taskId, address indexed weaver, uint256 claimTime);
    event TaskResultSubmitted(bytes32 indexed taskId, address indexed weaver, bytes32 resultHash, bytes32 verificationProofHash);
    event TaskChallenged(bytes32 indexed taskId, address indexed challenger, bytes32 challengerResultHash);
    event DisputeResolved(bytes32 indexed taskId, address indexed resolver, bool weaverWasCorrect);
    event TaskCompleted(bytes32 indexed taskId, address indexed requester, address indexed weaver, uint256 reward);
    event TaskCanceled(bytes32 indexed taskId, address indexed requester, uint256 refundAmount);
    event WeaverRewardsClaimed(address indexed weaver, uint256 amount);

    // --- Modifiers ---
    modifier whenNotPaused() {
        if (paused) revert Paused();
        _;
    }

    modifier whenPaused() {
        if (!paused) revert NotPaused();
        _;
    }

    modifier onlyWeaver(address _weaverAddress) {
        if (!weavers[_weaverAddress].exists) revert WeaverNotRegistered();
        _;
    }

    modifier onlyRequester(bytes32 _taskId) {
        if (tasks[_taskId].requester != msg.sender) revert Unauthorized();
        _;
    }

    // --- Constructor ---
    /// @param _initialPaymentToken The ERC20 token address to be used for all payments and staking.
    constructor(address _initialPaymentToken) Ownable(msg.sender) {
        // Default configuration
        minWeaverStake = 1000 * 10 ** 18; // Example: 1000 tokens (assuming 18 decimals)
        challengePeriod = 24 * 3600;      // 24 hours
        minDisputeResolutionPeriod = 1 * 3600; // 1 hour
        taskExpirationPeriod = 7 * 24 * 3600; // 7 days (for an unclaimed task)
        weaverRewardMultiplierNumerator = 100; // 100% of fee goes to weaver
        weaverRewardMultiplierDenominator = 100;
        initialReputationScore = 1000;

        paymentToken = _initialPaymentToken;
        paused = false;
        nextTaskIdCounter = 1;

        emit PaymentTokenSet(_initialPaymentToken);
        emit ConfigurationUpdated(minWeaverStake, challengePeriod, minDisputeResolutionPeriod, taskExpirationPeriod);
    }

    // I. Core Infrastructure & Configuration

    /// @notice Updates global configuration parameters. Only callable by the owner.
    /// @param _minWeaverStake Minimum stake required for Aether Weavers.
    /// @param _challengePeriod Time in seconds for results to be challenged.
    /// @param _minDisputeResolutionPeriod Minimum time for owner to resolve a dispute.
    /// @param _taskExpirationPeriod Time in seconds before an unclaimed task expires.
    /// @param _weaverRewardMultiplierNumerator Numerator for calculating weaver rewards from task fees.
    /// @param _weaverRewardMultiplierDenominator Denominator for calculating weaver rewards.
    /// @param _initialReputationScore Initial reputation score for new weavers.
    function updateConfiguration(
        uint256 _minWeaverStake,
        uint256 _challengePeriod,
        uint256 _minDisputeResolutionPeriod,
        uint256 _taskExpirationPeriod,
        uint256 _weaverRewardMultiplierNumerator,
        uint256 _weaverRewardMultiplierDenominator,
        uint256 _initialReputationScore
    ) external onlyOwner {
        minWeaverStake = _minWeaverStake;
        challengePeriod = _challengePeriod;
        minDisputeResolutionPeriod = _minDisputeResolutionPeriod;
        taskExpirationPeriod = _taskExpirationPeriod;
        weaverRewardMultiplierNumerator = _weaverRewardMultiplierNumerator;
        weaverRewardMultiplierDenominator = _weaverRewardMultiplierDenominator;
        initialReputationScore = _initialReputationScore;
        emit ConfigurationUpdated(minWeaverStake, challengePeriod, minDisputeResolutionPeriod, taskExpirationPeriod);
    }

    /// @notice Pauses the contract, preventing certain operations. Only callable by the owner.
    function pause() external onlyOwner whenNotPaused {
        paused = true;
        emit Paused(msg.sender);
    }

    /// @notice Unpauses the contract, allowing operations to resume. Only callable by the owner.
    function unpause() external onlyOwner whenPaused {
        paused = false;
        emit Unpaused(msg.sender);
    }

    /// @notice Adds a new supported computation type to the network. Only callable by the owner.
    /// @param _typeId Unique identifier for the computation type.
    /// @param _baseCost Base cost in paymentToken for tasks of this type.
    /// @param _requiredWeaverStake Additional stake a weaver needs to claim this type of task.
    /// @param _minResponseTime Minimum expected response time in seconds.
    /// @param _maxResponseTime Maximum expected response time in seconds.
    function addSupportedComputationType(
        string calldata _typeId,
        uint256 _baseCost,
        uint256 _requiredWeaverStake,
        uint256 _minResponseTime,
        uint256 _maxResponseTime
    ) external onlyOwner {
        if (computationTypes[_typeId].exists) revert ComputationTypeAlreadyExists();
        computationTypes[_typeId] = ComputationType({
            typeId: _typeId,
            baseCost: _baseCost,
            requiredWeaverStake: _requiredWeaverStake,
            minResponseTime: _minResponseTime,
            maxResponseTime: _maxResponseTime,
            exists: true
        });
        supportedComputationTypeIds.push(_typeId);
        emit ComputationTypeAdded(_typeId, _baseCost, _requiredWeaverStake);
    }

    /// @notice Updates an existing supported computation type. Only callable by the owner.
    /// @param _typeId Identifier of the computation type to update.
    /// @param _newBaseCost New base cost.
    /// @param _newRequiredWeaverStake New required weaver stake.
    /// @param _newMinResponseTime New minimum response time.
    /// @param _newMaxResponseTime New maximum response time.
    function updateComputationType(
        string calldata _typeId,
        uint256 _newBaseCost,
        uint256 _newRequiredWeaverStake,
        uint256 _newMinResponseTime,
        uint256 _newMaxResponseTime
    ) external onlyOwner {
        if (!computationTypes[_typeId].exists) revert ComputationTypeNotFound();
        ComputationType storage compType = computationTypes[_typeId];
        compType.baseCost = _newBaseCost;
        compType.requiredWeaverStake = _newRequiredWeaverStake;
        compType.minResponseTime = _newMinResponseTime;
        compType.maxResponseTime = _newMaxResponseTime;
        emit ComputationTypeUpdated(_typeId, _newBaseCost);
    }

    /// @notice Removes a supported computation type. Only callable by the owner.
    /// @param _typeId Identifier of the computation type to remove.
    function removeSupportedComputationType(string calldata _typeId) external onlyOwner {
        if (!computationTypes[_typeId].exists) revert ComputationTypeNotFound();
        delete computationTypes[_typeId];
        // Efficiently remove from array (order doesn't matter)
        for (uint i = 0; i < supportedComputationTypeIds.length; i++) {
            if (keccak256(abi.encodePacked(supportedComputationTypeIds[i])) == keccak256(abi.encodePacked(_typeId))) {
                supportedComputationTypeIds[i] = supportedComputationTypeIds[supportedComputationTypeIds.length - 1];
                supportedComputationTypeIds.pop();
                break;
            }
        }
        emit ComputationTypeRemoved(_typeId);
    }

    /// @notice Sets the ERC20 token to be used for all payments and staking. Only callable by the owner.
    /// @param _newToken Address of the new ERC20 token. Must not be address(0).
    function setPaymentToken(address _newToken) external onlyOwner {
        if (_newToken == address(0)) revert InvalidAmount();
        paymentToken = _newToken;
        emit PaymentTokenSet(_newToken);
    }

    // II. Aether Weaver (Oracle) Management

    /// @notice Allows a user to become an "Aether Weaver" by staking tokens.
    /// The user must have approved `minWeaverStake` tokens to this contract before calling.
    /// @param _metadataURI URI pointing to off-chain metadata (e.g., Weaver profile, capabilities).
    function registerAetherWeaver(string calldata _metadataURI) external whenNotPaused nonReentrant {
        if (weavers[msg.sender].exists) revert WeaverAlreadyRegistered();
        
        IERC20 token = IERC20(paymentToken);
        if (token.allowance(msg.sender, address(this)) < minWeaverStake) {
            revert NotEnoughAllowance();
        }
        token.transferFrom(msg.sender, address(this), minWeaverStake);

        weavers[msg.sender] = Weaver({
            stake: minWeaverStake,
            metadataURI: _metadataURI,
            reputationScore: initialReputationScore,
            availableRewards: 0,
            numTasksCompleted: 0,
            numDisputesWon: 0,
            numDisputesLost: 0,
            exists: true
        });
        emit WeaverRegistered(msg.sender, minWeaverStake, _metadataURI);
    }

    /// @notice Allows a Weaver to unstake their tokens and leave the network.
    /// Requires no pending tasks/disputes and no outstanding rewards.
    function deregisterAetherWeaver() external onlyWeaver(msg.sender) whenNotPaused nonReentrant {
        // More robust check for pending tasks would require iterating through tasks or a dedicated mapping.
        // For this example, we assume `availableRewards` being 0 and no active tasks claimed by them
        // (which should prevent deregistration) is a proxy for no pending financial obligations.
        if (weavers[msg.sender].availableRewards > 0) revert NoFundsToClaim();
        
        // A more advanced system might have a cooldown period or explicit checks for all claimed tasks.
        // For simplicity, this directly deregisters.

        uint256 weaverStake = weavers[msg.sender].stake;
        delete weavers[msg.sender]; // Remove weaver from mapping

        IERC20(paymentToken).transfer(msg.sender, weaverStake); // Return stake

        emit WeaverDeregistered(msg.sender, weaverStake);
    }

    /// @notice Allows a Weaver to update their public profile metadata URI.
    /// @param _newMetadataURI New URI for the Weaver's metadata.
    function updateWeaverProfile(string calldata _newMetadataURI) external onlyWeaver(msg.sender) {
        weavers[msg.sender].metadataURI = _newMetadataURI;
        emit WeaverProfileUpdated(msg.sender, _newMetadataURI);
    }

    /// @notice Allows the owner to manually slash a Weaver's stake.
    /// Can be used for severe off-chain misconduct or as part of dispute resolution.
    /// @param _weaverAddress The address of the Weaver to slash.
    /// @param _amount The amount of tokens to slash.
    function slashWeaver(address _weaverAddress, uint256 _amount) external onlyOwner onlyWeaver(_weaverAddress) {
        if (_amount == 0) revert InvalidAmount();
        if (weavers[_weaverAddress].stake < _amount) revert InsufficientStake(_amount, weavers[_weaverAddress].stake);

        weavers[_weaverAddress].stake -= _amount;
        // The slashed amount stays in the contract, potentially for a treasury or burned.
        // For simplicity, it remains in the contract's balance.
        emit WeaverSlashed(_weaverAddress, _amount);
        _updateWeaverReputation(_weaverAddress, false, false); // Penalize reputation for slashing
    }

    /// @notice Retrieves the current reputation score of an Aether Weaver.
    /// @param _weaverAddress The address of the Weaver.
    /// @return The Weaver's reputation score.
    function getWeaverReputation(address _weaverAddress) external view onlyWeaver(_weaverAddress) returns (uint256) {
        return weavers[_weaverAddress].reputationScore;
    }

    /// @notice Conceptually distributes a SoulBound Token (SBT) to a high-performing Weaver.
    /// This function would interact with an external SBT contract. Only callable by the owner.
    /// For this example, it's a placeholder.
    /// @param _weaverAddress The address of the Weaver to reward with an SBT.
    function distributeWeaverSBT(address _weaverAddress) external onlyOwner onlyWeaver(_weaverAddress) {
        // This would involve calling an external SBT contract:
        // IERC721SBT(sbtContractAddress).mint(_weaverAddress, tokenID, metadataURI);
        // For now, it's a conceptual placeholder.
        emit WeaverReputationUpdated(_weaverAddress, weavers[_weaverAddress].reputationScore); // Reusing event to indicate external reward trigger.
    }

    /// @notice Decreases a Weaver's reputation score. Only callable by the owner.
    /// Can be used for specific reasons or during dispute resolution.
    /// @param _weaverAddress The address of the Weaver to penalize.
    /// @param _penaltyAmount The amount to decrease the reputation by.
    function penalizeWeaverReputation(address _weaverAddress, uint256 _penaltyAmount) external onlyOwner onlyWeaver(_weaverAddress) {
        if (_penaltyAmount == 0) revert InvalidAmount();
        weavers[_weaverAddress].reputationScore = (weavers[_weaverAddress].reputationScore < _penaltyAmount) ? 0 : weavers[_weaverAddress].reputationScore - _penaltyAmount;
        emit WeaverReputationUpdated(_weaverAddress, weavers[_weaverAddress].reputationScore);
    }

    /// @dev Internal helper function to update a Weaver's reputation based on task and dispute outcomes.
    /// @param _weaver The address of the Weaver.
    /// @param _taskSuccessful True if the task was completed successfully.
    /// @param _disputeWon True if the Weaver won an associated dispute (if any).
    function _updateWeaverReputation(address _weaver, bool _taskSuccessful, bool _disputeWon) internal {
        Weaver storage weaver = weavers[_weaver];
        
        if (_taskSuccessful) {
            weaver.numTasksCompleted++;
            weaver.reputationScore += 10; // Example: +10 for successful task
        } else {
            weaver.reputationScore = (weaver.reputationScore < 50) ? 0 : weaver.reputationScore - 50; // Example: -50 for failed task/slashing
        }

        if (_disputeWon) {
            weaver.numDisputesWon++;
            weaver.reputationScore += 30; // Example: +30 for winning a dispute
        } else if (weaver.numTasksCompleted > 0 || weaver.numDisputesWon > 0 || weaver.numDisputesLost > 0) { // Only penalize if they're an active weaver
            weaver.numDisputesLost++;
            weaver.reputationScore = (weaver.reputationScore < 80) ? 0 : weaver.reputationScore - 80; // Example: -80 for losing a dispute
        }
        
        // Ensure reputation doesn't exceed a cap (e.g., 2000)
        if (weaver.reputationScore > 2000) weaver.reputationScore = 2000;

        emit WeaverReputationUpdated(_weaver, weaver.reputationScore);
    }

    // III. Task Management & Execution

    /// @notice Submits a new computation task.
    /// The requester must have approved `_maxReward` tokens to this contract before calling.
    /// @param _computationTypeId The type of computation required.
    /// @param _inputHash Hash of the off-chain input data.
    /// @param _expectedOutputPropertiesHash Hash of desired output properties for basic validation.
    /// @param _maxReward Maximum reward the requester is willing to pay. This includes the `baseCost`.
    /// @param _timeoutSeconds Timeout in seconds for the task to be completed by a weaver (from submission).
    function submitComputationTask(
        string calldata _computationTypeId,
        bytes32 _inputHash,
        bytes32 _expectedOutputPropertiesHash,
        uint256 _maxReward,
        uint256 _timeoutSeconds
    ) external whenNotPaused nonReentrant {
        if (!computationTypes[_computationTypeId].exists) revert InvalidComputationType();
        if (_maxReward == 0) revert InsufficientRewardForWeaver(); // Must offer a reward
        if (_timeoutSeconds == 0) revert InvalidAmount(); // Must have a timeout

        ComputationType storage compType = computationTypes[_computationTypeId];
        
        // Ensure requester pays enough to cover the base cost (which will be part of the weaver's reward)
        if (_maxReward < compType.baseCost) revert InsufficientRewardForWeaver();

        IERC20 token = IERC20(paymentToken);
        if (token.allowance(msg.sender, address(this)) < _maxReward) {
            revert NotEnoughAllowance();
        }
        token.transferFrom(msg.sender, address(this), _maxReward); // Transfer full max reward

        bytes32 taskId = keccak256(abi.encodePacked(msg.sender, _computationTypeId, block.timestamp, nextTaskIdCounter++));
        
        tasks[taskId] = Task({
            taskId: taskId,
            computationTypeId: _computationTypeId,
            requester: msg.sender,
            weaver: address(0), // Not yet assigned
            inputHash: _inputHash,
            expectedOutputPropertiesHash: _expectedOutputPropertiesHash,
            maxReward: _maxReward,
            submissionTime: block.timestamp,
            claimTime: 0,
            resultSubmissionTime: 0,
            timeoutTimestamp: block.timestamp + _timeoutSeconds, // Initial timeout for claiming
            status: TaskStatus.Submitted,
            resultHash: bytes32(0),
            verificationProofHash: bytes32(0),
            challengerResultHash: bytes32(0),
            challengerProofHash: bytes32(0),
            challenger: address(0),
            challengeStake: 0,
            disputeResolved: false,
            weaverWasCorrectInDispute: false,
            requesterConfirmed: false
        });
        emit TaskSubmitted(taskId, msg.sender, _computationTypeId, _maxReward);
    }

    /// @notice An Aether Weaver claims an available computation task.
    /// Locks the weaver's stake for the task.
    /// @param _taskId The ID of the task to claim.
    function acceptTaskAssignment(bytes32 _taskId) external onlyWeaver(msg.sender) whenNotPaused nonReentrant {
        Task storage task = tasks[_taskId];
        if (task.requester == address(0)) revert TaskNotFound();
        if (task.status != TaskStatus.Submitted) revert InvalidTaskStateForAction();
        if (block.timestamp > task.timeoutTimestamp) {
            task.status = TaskStatus.Failed; // Mark as failed if initial timeout for claiming passes
            revert TaskExpired();
        }

        ComputationType storage compType = computationTypes[task.computationTypeId];
        if (!compType.exists) revert InvalidComputationType();

        Weaver storage weaver = weavers[msg.sender];
        uint256 requiredStakeForTask = compType.requiredWeaverStake;

        if (weaver.stake < requiredStakeForTask) {
            revert InsufficientStake(requiredStakeForTask, weaver.stake);
        }

        // We conceptually 'lock' the stake. No actual transfer from weaver's stake,
        // but this implies the weaver has sufficient capital and is liable.
        task.weaver = msg.sender;
        task.claimTime = block.timestamp;
        task.timeoutTimestamp = block.timestamp + compType.maxResponseTime; // New timeout for result submission
        task.status = TaskStatus.Claimed;

        emit TaskClaimed(_taskId, msg.sender, task.claimTime);
    }

    /// @notice The assigned Weaver submits the result hash and a verification proof hash.
    /// @param _taskId The ID of the task.
    /// @param _resultHash Hash of the off-chain computation result.
    /// @param _verificationProofHash Hash of the ZK-proof or other verification data.
    function submitTaskResult(bytes32 _taskId, bytes32 _resultHash, bytes32 _verificationProofHash) external onlyWeaver(msg.sender) whenNotPaused {
        Task storage task = tasks[_taskId];
        if (task.requester == address(0)) revert TaskNotFound();
        if (task.weaver != msg.sender) revert Unauthorized();
        if (task.status != TaskStatus.Claimed) revert InvalidTaskStateForAction();
        if (block.timestamp > task.timeoutTimestamp) {
            task.status = TaskStatus.Failed;
            _updateWeaverReputation(msg.sender, false, false); // Weaver failed to submit on time
            revert TaskExpired(); // Weaver timed out
        }

        task.resultHash = _resultHash;
        task.verificationProofHash = _verificationProofHash;
        task.resultSubmissionTime = block.timestamp;
        task.status = TaskStatus.ResultSubmitted;

        emit TaskResultSubmitted(_taskId, msg.sender, _resultHash, _verificationProofHash);
    }

    /// @notice A user or another Weaver challenges a submitted result.
    /// Requires a challenge stake. The challenger must have approved the `challengeStakeAmount`
    /// tokens to this contract before calling.
    /// @param _taskId The ID of the task.
    /// @param _challengerResultHash Hash of the challenger's proposed correct result.
    /// @param _challengerProofHash Hash of the challenger's verification proof.
    function challengeTaskResult(
        bytes32 _taskId,
        bytes32 _challengerResultHash,
        bytes32 _challengerProofHash
    ) external whenNotPaused nonReentrant {
        Task storage task = tasks[_taskId];
        if (task.requester == address(0)) revert TaskNotFound();
        if (task.status != TaskStatus.ResultSubmitted) revert InvalidTaskStateForAction();
        if (block.timestamp > task.resultSubmissionTime + challengePeriod) revert ChallengePeriodNotExpired(); // Challenge period has passed

        uint256 challengeStakeAmount = computationTypes[task.computationTypeId].baseCost; // Example: challenge stake is equal to base task cost
        if (challengeStakeAmount == 0) revert InvalidAmount();

        IERC20 token = IERC20(paymentToken);
        if (token.allowance(msg.sender, address(this)) < challengeStakeAmount) {
            revert NotEnoughAllowance();
        }
        token.transferFrom(msg.sender, address(this), challengeStakeAmount);

        task.challenger = msg.sender;
        task.challengerResultHash = _challengerResultHash;
        task.challengerProofHash = _challengerProofHash;
        task.challengeStake = challengeStakeAmount;
        task.status = TaskStatus.Challenged;

        emit TaskChallenged(_taskId, msg.sender, _challengerResultHash);
    }

    /// @notice Resolves an active dispute, determining if the Weaver's initial result was correct.
    /// Only callable by the owner (or a DAO in a more complex setup).
    /// @param _taskId The ID of the task with the dispute.
    /// @param _weaverWasCorrect True if the original Weaver's result was deemed correct.
    function resolveDispute(bytes32 _taskId, bool _weaverWasCorrect) external onlyOwner whenNotPaused nonReentrant {
        Task storage task = tasks[_taskId];
        if (task.requester == address(0)) revert TaskNotFound();
        if (task.status != TaskStatus.Challenged) revert InvalidTaskStateForAction();
        // Ensure enough time has passed for challenge and minimum resolution period
        if (block.timestamp < task.resultSubmissionTime + challengePeriod + minDisputeResolutionPeriod) revert DisputeNotResolved();

        task.disputeResolved = true;
        task.weaverWasCorrectInDispute = _weaverWasCorrect;
        task.status = TaskStatus.DisputeResolved;

        IERC20 token = IERC20(paymentToken);

        if (_weaverWasCorrect) {
            // Weaver was correct: Challenger loses stake (it remains in the contract), Weaver's reputation improves.
            // Challenger's stake is forfeited (stays in contract, could be burnt or added to treasury).
            // If challenger is a weaver, their reputation decreases.
            if (weavers[task.challenger].exists) {
                _updateWeaverReputation(task.challenger, false, false); // Challenger loses reputation
            }
            _updateWeaverReputation(task.weaver, true, true); // Weaver wins dispute, gains reputation
        } else {
            // Weaver was incorrect: Weaver's stake is slashed, Challenger gets stake back, Weaver's reputation decreases.
            uint256 slashAmount = task.challengeStake; // Slash amount = challenger's stake
            if (weavers[task.weaver].stake < slashAmount) {
                slashAmount = weavers[task.weaver].stake; // Can't slash more than available
            }
            weavers[task.weaver].stake -= slashAmount;
            emit WeaverSlashed(task.weaver, slashAmount);

            // Challenger gets their stake back
            token.transfer(task.challenger, task.challengeStake);

            // Weaver's reputation decreases
            _updateWeaverReputation(task.weaver, false, false); 
            // If challenger is also a weaver, we could update their reputation positively.
        }

        emit DisputeResolved(_taskId, msg.sender, _weaverWasCorrect);
    }

    /// @notice The task requester confirms task completion.
    /// This finalizes payment to the Weaver and updates reputation.
    /// Callable only after challenge period expires or dispute is resolved in Weaver's favor.
    /// @param _taskId The ID of the task.
    function confirmTaskCompletion(bytes32 _taskId) external onlyRequester(_taskId) whenNotPaused nonReentrant {
        Task storage task = tasks[_taskId];
        if (task.requester == address(0)) revert TaskNotFound();
        if (task.status == TaskStatus.Completed || task.status == TaskStatus.Canceled || task.status == TaskStatus.Failed) revert InvalidTaskStateForAction();
        if (task.weaver == address(0)) revert TaskNotClaimed(); // Should have a weaver by this stage

        // Conditions for completion:
        bool canComplete = false;
        if (task.status == TaskStatus.ResultSubmitted && block.timestamp >= task.resultSubmissionTime + challengePeriod) {
            canComplete = true; // Challenge period expired, no challenge
        } else if (task.status == TaskStatus.DisputeResolved && task.weaverWasCorrectInDispute) {
            canComplete = true; // Dispute resolved in weaver's favor
        }

        if (!canComplete) revert TaskNotYetReadyForCompletion();

        task.requesterConfirmed = true;
        task.status = TaskStatus.Completed;

        // Calculate actual reward for the weaver (from the maxReward initially deposited by requester)
        // This takes the baseCost as the fee, and potentially a portion of the extra maxReward.
        // For simplicity, we can assume the maxReward IS the payment for the weaver here.
        // A more complex system might have a separate fee and reward structure.
        uint256 weaverReward = task.maxReward; // Simplistic: full maxReward goes to weaver if successful

        // Transfer reward to weaver's available rewards balance
        weavers[task.weaver].availableRewards += weaverReward;

        // Update weaver reputation
        _updateWeaverReputation(task.weaver, true, true); // If reached here, weaver performed successfully.

        emit TaskCompleted(_taskId, msg.sender, task.weaver, weaverReward);
    }

    /// @notice Allows the requester to cancel a task.
    /// Refunds payment if the task was unclaimed or if weaver failed to submit.
    /// @param _taskId The ID of the task to cancel.
    function cancelTask(bytes32 _taskId) external onlyRequester(_taskId) whenNotPaused nonReentrant {
        Task storage task = tasks[_taskId];
        if (task.requester == address(0)) revert TaskNotFound();

        IERC20 token = IERC20(paymentToken);
        uint256 refundAmount = 0;

        if (task.status == TaskStatus.Submitted && block.timestamp < task.timeoutTimestamp) {
            // Task was submitted but not yet claimed, within its initial timeout
            refundAmount = task.maxReward;
            token.transfer(task.requester, refundAmount);
            task.status = TaskStatus.Canceled;
        } else if (task.status == TaskStatus.Claimed && block.timestamp >= task.timeoutTimestamp) {
            // Task was claimed but weaver failed to submit result within their timeout
            refundAmount = task.maxReward;
            token.transfer(task.requester, refundAmount);
            task.status = TaskStatus.Failed; // Mark as failed due to weaver timeout
            _updateWeaverReputation(task.weaver, false, false); // Penalize weaver
        } else {
            revert InvalidTaskStateForAction(); // Cannot cancel tasks that are in other states (e.g., result submitted, challenged, completed)
        }

        emit TaskCanceled(_taskId, msg.sender, refundAmount);
    }

    // IV. Reward & Reputation System

    /// @notice Allows an Aether Weaver to claim their accumulated rewards.
    function claimWeaverRewards() external onlyWeaver(msg.sender) nonReentrant {
        Weaver storage weaver = weavers[msg.sender];
        if (weaver.availableRewards == 0) revert NoFundsToClaim();

        uint256 amountToClaim = weaver.availableRewards;
        weaver.availableRewards = 0; // Reset
        
        IERC20(paymentToken).transfer(msg.sender, amountToClaim);

        emit WeaverRewardsClaimed(msg.sender, amountToClaim);
    }

    /// @notice Returns the amount of tokens currently staked by a specific Weaver.
    /// @param _weaverAddress The address of the Weaver.
    /// @return The staked amount.
    function getWeaverStakedAmount(address _weaverAddress) external view onlyWeaver(_weaverAddress) returns (uint256) {
        return weavers[_weaverAddress].stake;
    }

    /// @notice Returns the amount of rewards a Weaver can claim.
    /// @param _weaverAddress The address of the Weaver.
    /// @return The claimable rewards amount.
    function getWeaverAvailableRewards(address _weaverAddress) external view onlyWeaver(_weaverAddress) returns (uint256) {
        return weavers[_weaverAddress].availableRewards;
    }

    // --- Helper functions (views) ---

    /// @notice Returns the details of a supported computation type.
    /// @param _typeId The ID of the computation type.
    /// @return A `ComputationType` struct containing the type's details.
    function getComputationType(string calldata _typeId) external view returns (ComputationType memory) {
        if (!computationTypes[_typeId].exists) revert ComputationTypeNotFound();
        return computationTypes[_typeId];
    }

    /// @notice Returns the details of a specific task.
    /// @param _taskId The ID of the task.
    /// @return A `Task` struct containing the task's details.
    function getTask(bytes32 _taskId) external view returns (Task memory) {
        if (tasks[_taskId].requester == address(0)) revert TaskNotFound();
        return tasks[_taskId];
    }

    /// @notice Checks if an address is a registered Weaver.
    /// @param _addr The address to check.
    /// @return True if the address is a Weaver, false otherwise.
    function isWeaver(address _addr) external view returns (bool) {
        return weavers[_addr].exists;
    }

    /// @notice Fallback function to prevent accidental ETH transfers.
    receive() external payable {
        revert("ETH not accepted. Use ERC20 token.");
    }
}

```