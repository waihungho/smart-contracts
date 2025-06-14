Okay, let's design a complex, advanced, and creative smart contract concept focusing on dynamic asset transformation, scarcity generation, and unique NFT mechanics. We'll call it the "QuantumLeap Protocol".

**Concept:** Users deposit a base token ("Chronon") into "Temporal Pods" for a fixed duration. Upon successful completion of the lock period, unlocking the pod triggers a probabilistic outcome determined by factors like lock duration, amount, and protocol state. Outcomes can include receiving back some Chronons, gaining a rare token ("Singularity Shard"), or minting a unique, dynamic NFT ("Entropic Key") with properties influenced by the locking parameters. Entropic Keys can then be "attuned" by spending tokens or "combined" to potentially yield rarer keys.

This incorporates:
*   **Time-locked deposits:** Standard, but foundational.
*   **Probabilistic Outcomes:** Introduce randomness/scarcity.
*   **Multiple Asset Outputs:** Chronons, Shards (fungible), Keys (non-fungible).
*   **Dynamic NFTs:** Key properties are set at minting based on input, and can be modified later.
*   **NFT Utility/Sinks:** Attuning and combining Keys consumes tokens and potentially burns NFTs, creating economic sinks.
*   **Batch Operations:** For user convenience.
*   **Admin Controls:** For parameter tuning and pausing.

We'll use OpenZeppelin libraries for standard implementations (like ERC721, Ownable, Pausable) but focus on the custom logic built around them.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// --- Outline ---
// 1. State Variables & Constants
//    - Token addresses (Chronon, SingularityShard)
//    - Protocol parameters (lock times, probabilities, fees)
//    - Counters for Pods and Keys
//    - Mappings for Pods and Key Data
//    - Lists/Mappings to track user's Pods and Keys (Protocol side)
//    - Admin/Fee recipient
// 2. Structs
//    - TemporalPod: Details of a token lock instance
//    - EntropicKeyData: Dynamic properties of an Entropic Key NFT
// 3. Events
//    - Tracking key actions (Lock, Unlock, Claim, Attune, Combine, Fee)
// 4. Errors
//    - Custom errors for specific failure conditions
// 5. Modifiers
//    - Standard Pausable
// 6. Constructor
//    - Initialize protocol parameters and token addresses
// 7. Admin Functions (Owner only)
//    - setParameters: Adjust lock times, probabilities, fee
//    - setProtocolFeeRecipient: Change fee address
//    - pause / unpause: Control protocol activity
//    - withdrawProtocolFees: Collect accumulated fees
// 8. User Functions (Core Interactions)
//    - lockChronons: Deposit Chronons into a new Temporal Pod
//    - extendLockDuration: Increase lock time of an existing Pod
//    - unlockPod: Trigger the outcome logic for a completed lock
//    - claimPodContents: Claim the resulting assets/NFT from an unlocked Pod
//    - attuneKey: Spend tokens to modify an Entropic Key's properties
//    - combineKeys: Burn multiple Entropic Keys to potentially create a new one
//    - burnKey: Burn an owned Entropic Key
//    - batchLockChronons: Lock multiple amounts/durations in one tx
//    - batchUnlockPods: Unlock multiple pods in one tx
//    - batchClaimPodContents: Claim multiple pods in one tx
// 9. View Functions (Read State)
//    - getParameters: Retrieve current protocol parameters
//    - getProtocolFeeRecipient: Get fee address
//    - getPod: Get data for a specific Temporal Pod
//    - getUserPods: Get list of Pod IDs for a user
//    - getKeyData: Get dynamic data for an Entropic Key
//    - getUserKeys: Get list of Key IDs for a user
//    - getTotalPods: Total number of pods created
//    - getTotalKeys: Total number of keys minted
//    - getProtocolChrononBalance: Contract's Chronon balance
//    - getProtocolShardBalance: Contract's Shard balance
// 10. Internal Functions
//    - _determineUnlockOutcome: Logic for probabilistic outcome calculation
//    - _mintSingularityShards: Handle Shard distribution
//    - _mintEntropicKey: Handle Entropic Key minting and data initialization
//    - _burnKey: Internal function to burn an Entropic Key
//    - _transferChronons: Handle Chronon transfers (user/fee)
// 11. ERC721 Overrides (EntropicKey specific)
//    - tokenURI: Generate metadata URI for Keys
//    - supportsInterface: Declare ERC721 and ERC165 support

// --- Function Summary ---

// Admin Functions:
// 1.  constructor(address _chrononToken, address _singularityShardToken, address _protocolFeeRecipient) - Initializes the contract, sets token addresses and initial parameters.
// 2.  setParameters(uint256 minLockDuration_, uint256 maxLockDuration_, uint256 outcomeProbBasePoint_, uint256 keyProbMultiplierPerDay_, uint256 shardProbMultiplierPer1000Chronons_, uint256 keyAttuneCostChronons_, uint256 keyCombineCostChronons_, uint256 protocolFeePercent_) - Updates various protocol parameters (Owner only).
// 3.  setProtocolFeeRecipient(address _protocolFeeRecipient) - Sets the address receiving protocol fees (Owner only).
// 4.  pause() - Pauses core user interactions (locking, unlocking, claiming, key actions) (Owner only).
// 5.  unpause() - Unpauses core user interactions (Owner only).
// 6.  withdrawProtocolFees() - Allows the owner to withdraw collected Chronon fees from the contract balance.

// User Functions:
// 7.  lockChronons(uint256 amount, uint256 durationInSeconds) - Deposits `amount` of Chronons for `durationInSeconds`, creating a new Temporal Pod. Requires prior approval.
// 8.  extendLockDuration(uint256 podId, uint256 additionalDurationInSeconds) - Increases the lock duration for an existing, active Pod owned by the caller.
// 9.  unlockPod(uint256 podId) - Triggers the outcome determination logic for a Pod whose lock duration has completed. Marks the pod as unlocked.
// 10. claimPodContents(uint256 podId) - Transfers the determined outcome (Chronons, Shards, Key) to the user after a Pod has been unlocked.
// 11. attuneKey(uint256 keyId, uint256 costChronons) - Spends Chronons (requires approval) to potentially modify properties of an owned Entropic Key.
// 12. combineKeys(uint256[] memory keyIds) - Burns multiple owned Entropic Keys (`keyIds`) to potentially mint a new, different Key. Requires keyIds.length > 1 and a cost in Chronons (requires approval).
// 13. burnKey(uint256 keyId) - Burns an owned Entropic Key, removing it from existence.
// 14. batchLockChronons(uint256[] memory amounts, uint256[] memory durationsInSeconds) - Deposits multiple amounts for multiple durations in a single transaction. Requires prior approval for total amount.
// 15. batchUnlockPods(uint256[] memory podIds) - Unlocks multiple completed pods in a single transaction.
// 16. batchClaimPodContents(uint256[] memory podIds) - Claims contents for multiple unlocked pods in a single transaction.

// View Functions:
// 17. getParameters() - Returns the current protocol parameters struct.
// 18. getProtocolFeeRecipient() - Returns the address designated to receive fees.
// 19. getPod(uint256 podId) - Returns details of a specific Temporal Pod.
// 20. getUserPods(address user) - Returns an array of Temporal Pod IDs owned by `user`.
// 21. getKeyData(uint256 keyId) - Returns the dynamic data associated with an Entropic Key NFT.
// 22. getUserKeys(address user) - Returns an array of Entropic Key IDs owned by `user`.
// 23. getTotalPods() - Returns the total number of Temporal Pods ever created.
// 24. getTotalKeys() - Returns the total number of Entropic Keys ever minted.
// 25. getProtocolChrononBalance() - Returns the contract's current balance of Chronon tokens.
// 26. getProtocolShardBalance() - Returns the contract's current balance of Singularity Shard tokens.

// Internal Functions (Helper logic, not directly callable externally):
// - _determineUnlockOutcome(uint256 podId, uint256 amount, uint256 duration, uint256 lockTimestamp) - Core logic to calculate the probabilistic outcome of unlocking a pod.
// - _mintSingularityShards(address recipient, uint256 amount) - Handles the actual transfer/minting of Shards.
// - _mintEntropicKey(address recipient, uint256 podId, uint256 amount, uint256 duration, uint256 lockTimestamp) - Handles minting an Entropic Key and setting initial dynamic data.
// - _burnKey(uint256 keyId) - Handles the actual burning of an Entropic Key.
// - _transferChronons(address recipient, uint256 amount) - Handles Chronon transfers securely.

// ERC721 Overrides (Implemented functions for EntropicKey):
// - tokenURI(uint256 keyId) - Returns the metadata URI for a specific Entropic Key.
// - supportsInterface(bytes4 interfaceId) - Standard ERC165 implementation.

contract QuantumLeapProtocol is ERC721, Ownable, Pausable, ReentrancyGuard {
    using Counters for Counters.Counter;

    IERC20 public immutable CHRONON_TOKEN;
    IERC20 public immutable SINGULARITY_SHARD_TOKEN;

    address private _protocolFeeRecipient;

    Counters.Counter private _podIdCounter;
    Counters.Counter private _keyIdCounter;

    // Protocol Parameters (Adjustable by Owner)
    struct ProtocolParameters {
        uint256 minLockDuration; // Minimum lock time in seconds
        uint256 maxLockDuration; // Maximum lock time in seconds
        uint256 outcomeProbBasePoint; // Base chance (e.g., 7000 = 70.00%) for Chronon return
        uint256 keyProbMultiplierPerDay; // Multiplier added to key probability per day of lock (e.g., 10 = 0.10%)
        uint256 shardProbMultiplierPer1000Chronons; // Multiplier added to shard probability per 1000 Chronons locked (e.g., 5 = 0.05%)
        uint256 keyAttuneCostChronons; // Base cost to attune a key
        uint256 keyCombineCostChronons; // Base cost to combine keys
        uint256 protocolFeePercent; // Percentage of Chronon return taken as fee (basis points, e.g., 500 = 5%)
    }

    ProtocolParameters public protocolParameters;

    // --- Temporal Pods ---
    enum PodStatus { Locked, Unlocked, Claimed }

    struct TemporalPod {
        address locker;
        uint256 amount;
        uint256 duration; // in seconds
        uint256 lockTimestamp;
        uint256 unlockTimestamp;
        PodStatus status;
        // Determined outcome - stored after unlock
        bytes outcomeData; // Abi-encoded tuple: (uint8 outcomeType, uint256 value1, uint256 value2)
                          // outcomeType: 0=Chronons, 1=Shards, 2=Key
                          // value1, value2: depend on outcomeType (e.g., Chronon amount, Shard amount, Key ID)
    }

    mapping(uint256 => TemporalPod) public pods;
    mapping(address => uint256[]) private _userPods; // Track pod IDs per user

    // --- Entropic Keys (NFT) ---
    // Dynamic data associated with each Entropic Key NFT
    struct EntropicKeyData {
        uint256 creationPodId; // Link back to the pod that created it
        uint256 resonanceScore; // Score that can be increased via attuning
        bytes32 coreAttribute; // An attribute derived from lock parameters (e.g., hash of params)
        uint8 colorState; // A state that can be changed via attuning (e.g., 0-255)
        // Add more dynamic properties as needed
    }

    mapping(uint256 => EntropicKeyData) public entropicKeyData;
     mapping(address => uint256[]) private _userKeys; // Track key IDs per user (redundant with ERC721 enumerable, but useful for protocol logic)


    // --- Events ---
    event ChrononsLocked(address indexed locker, uint256 indexed podId, uint256 amount, uint256 duration, uint256 unlockTimestamp);
    event LockDurationExtended(uint256 indexed podId, uint256 newUnlockTimestamp);
    event PodUnlocked(uint256 indexed podId, address indexed locker, uint8 outcomeType, uint256 value1, uint256 value2);
    event PodContentsClaimed(uint256 indexed podId, address indexed locker, uint8 outcomeType, uint256 value1, uint256 value2);
    event KeyAttuned(address indexed user, uint256 indexed keyId, uint256 resonanceScore, uint8 colorState);
    event KeysCombined(address indexed user, uint256[] indexed burnedKeyIds, uint256 indexed newKeyId);
    event KeyBurned(address indexed user, uint256 indexed keyId);
    event ProtocolFeesWithdrawn(address indexed recipient, uint256 amount);
    event ParametersUpdated(ProtocolParameters newParams);
    event FeeRecipientUpdated(address indexed newRecipient);

    // --- Errors ---
    error InvalidDuration();
    error InsufficientAllowanceOrBalance();
    error PodNotFound();
    error PodNotOwned();
    error PodNotLocked();
    error PodNotUnlocked();
    error PodAlreadyClaimed();
    error PodLockNotExpired();
    error CannotExtendPastMaxDuration();
    error KeyNotFound();
    error KeyNotOwned();
    error InvalidKeyCombination();
    error BatchLengthMismatch();
    error ZeroAddressFeeRecipient();
    error ZeroAmount();
    error InvalidFeePercentage();

    // --- Constructor ---
    constructor(
        address _chrononToken,
        address _singularityShardToken,
        address _protocolFeeRecipient
    ) ERC721("EntropicKey", "EKEY") Ownable(msg.sender) {
        if (_chrononToken == address(0) || _singularityShardToken == address(0)) {
            revert ZeroAddress();
        }
        if (_protocolFeeRecipient == address(0)) {
            revert ZeroAddressFeeRecipient();
        }

        CHRONON_TOKEN = IERC20(_chrononToken);
        SINGULARITY_SHARD_TOKEN = IERC20(_singularityShardToken);
        _protocolFeeRecipient = _protocolFeeRecipient;

        // Set initial parameters (example values - adjust as needed)
        protocolParameters = ProtocolParameters({
            minLockDuration: 1 days,
            maxLockDuration: 365 days,
            outcomeProbBasePoint: 7000, // 70% base chance of Chronon return
            keyProbMultiplierPerDay: 10, // +0.10% chance of Key per day
            shardProbMultiplierPer1000Chronons: 5, // +0.05% chance of Shard per 1000 Chronons
            keyAttuneCostChronons: 100 ether, // Example cost to attune
            keyCombineCostChronons: 500 ether, // Example cost to combine
            protocolFeePercent: 500 // 5% fee on Chronon returns
        });
    }

    // --- Admin Functions ---

    /**
     * @notice Allows the owner to update core protocol parameters.
     * @param minLockDuration_ Minimum lock time in seconds.
     * @param maxLockDuration_ Maximum lock time in seconds.
     * @param outcomeProbBasePoint_ Base chance (0-10000) for Chronon return outcome.
     * @param keyProbMultiplierPerDay_ Multiplier added to key probability per day of lock (in basis points per day, e.g., 10 for 0.10%).
     * @param shardProbMultiplierPer1000Chronons_ Multiplier added to shard probability per 1000 Chronons locked (in basis points per 1000 Chronons, e.g., 5 for 0.05%).
     * @param keyAttuneCostChronons_ Base cost in Chronons to attune a key.
     * @param keyCombineCostChronons_ Base cost in Chronons to combine keys.
     * @param protocolFeePercent_ Percentage of Chronon return taken as fee (in basis points, e.g., 500 for 5%). Max 10000.
     */
    function setParameters(
        uint256 minLockDuration_,
        uint256 maxLockDuration_,
        uint256 outcomeProbBasePoint_,
        uint256 keyProbMultiplierPerDay_,
        uint256 shardProbMultiplierPer1000Chronons_,
        uint256 keyAttuneCostChronons_,
        uint256 keyCombineCostChronons_,
        uint256 protocolFeePercent_
    ) external onlyOwner {
        if (minLockDuration_ == 0 || maxLockDuration_ == 0 || minLockDuration_ > maxLockDuration_) {
             revert InvalidDuration();
        }
        if (outcomeProbBasePoint_ > 10000) {
             revert InvalidArgument("outcomeProbBasePoint_"); // Using generic OZ error
        }
         if (protocolFeePercent_ > 10000) {
             revert InvalidFeePercentage();
        }

        protocolParameters = ProtocolParameters({
            minLockDuration: minLockDuration_,
            maxLockDuration: maxLockDuration_,
            outcomeProbBasePoint: outcomeProbBasePoint_,
            keyProbMultiplierPerDay: keyProbMultiplierPerDay_,
            shardProbMultiplierPer1000Chronons: shardProbMultiplierPer1000Chronons_,
            keyAttuneCostChronons: keyAttuneCostChronons_,
            keyCombineCostChronons: keyCombineCostChronons_,
            protocolFeePercent: protocolFeePercent_
        });

        emit ParametersUpdated(protocolParameters);
    }

    /**
     * @notice Allows the owner to set the address that receives protocol fees.
     * @param _protocolFeeRecipient The new address for fee collection.
     */
    function setProtocolFeeRecipient(address _protocolFeeRecipient) external onlyOwner {
        if (_protocolFeeRecipient == address(0)) {
            revert ZeroAddressFeeRecipient();
        }
        _protocolFeeRecipient = _protocolFeeRecipient;
        emit FeeRecipientUpdated(_protocolFeeRecipient);
    }

    /**
     * @notice Allows the owner to withdraw accumulated Chronon fees.
     */
    function withdrawProtocolFees() external onlyOwner nonReentrant {
        uint256 balance = CHRONON_TOKEN.balanceOf(address(this));
        uint256 contractLockedBalance = 0;
        // Sum all locked Chronons in active pods to ensure we don't withdraw those
        uint256 totalPods = _podIdCounter.current();
        for (uint256 i = 1; i <= totalPods; ++i) {
             if (pods[i].status == PodStatus.Locked) {
                 contractLockedBalance += pods[i].amount;
             }
             // Note: This loop can be gas intensive if there are many pods.
             // A better approach for large protocols would be to track total locked amount separately.
             // Keeping it simple here for demonstration.
        }


        uint256 withdrawable = balance > contractLockedBalance ? balance - contractLockedBalance : 0;

        if (withdrawable == 0) {
             return; // Nothing to withdraw
        }

        _transferChronons(_protocolFeeRecipient, withdrawable);

        emit ProtocolFeesWithdrawn(_protocolFeeRecipient, withdrawable);
    }


    // --- User Functions ---

    /**
     * @notice Deposits Chronons into a new Temporal Pod for a specified duration.
     * Requires the user to have approved this contract to spend the Chronons.
     * @param amount The amount of Chronons to lock.
     * @param durationInSeconds The duration of the lock in seconds.
     * @return podId The ID of the newly created pod.
     */
    function lockChronons(uint256 amount, uint256 durationInSeconds) external nonReentrant whenNotPaused returns (uint256 podId) {
        if (amount == 0) revert ZeroAmount();
        if (durationInSeconds < protocolParameters.minLockDuration || durationInSeconds > protocolParameters.maxLockDuration) {
            revert InvalidDuration();
        }

        // Transfer tokens from user to contract
        if (!CHRONON_TOKEN.transferFrom(msg.sender, address(this), amount)) {
             revert InsufficientAllowanceOrBalance();
        }

        _podIdCounter.increment();
        podId = _podIdCounter.current();
        uint256 lockTimestamp = block.timestamp;
        uint256 unlockTimestamp = lockTimestamp + durationInSeconds;

        pods[podId] = TemporalPod({
            locker: msg.sender,
            amount: amount,
            duration: durationInSeconds,
            lockTimestamp: lockTimestamp,
            unlockTimestamp: unlockTimestamp,
            status: PodStatus.Locked,
            outcomeData: "" // Will be set on unlock
        });

        _userPods[msg.sender].push(podId);

        emit ChrononsLocked(msg.sender, podId, amount, durationInSeconds, unlockTimestamp);
    }

     /**
     * @notice Deposits multiple amounts of Chronons into new Temporal Pods with specified durations in a single transaction.
     * Requires the user to have approved this contract to spend the total amount of Chronons.
     * @param amounts An array of Chronon amounts to lock.
     * @param durationsInSeconds An array of durations (in seconds) for each lock.
     */
    function batchLockChronons(uint256[] memory amounts, uint256[] memory durationsInSeconds) external nonReentrant whenNotPaused {
        if (amounts.length == 0 || amounts.length != durationsInSeconds.length) {
            revert BatchLengthMismatch();
        }

        uint256 totalAmount = 0;
        for (uint256 i = 0; i < amounts.length; ++i) {
             if (amounts[i] == 0) revert ZeroAmount();
             if (durationsInSeconds[i] < protocolParameters.minLockDuration || durationsInSeconds[i] > protocolParameters.maxLockDuration) {
                 revert InvalidDuration();
             }
             totalAmount += amounts[i];
        }

         // Transfer total tokens from user to contract
         if (!CHRONON_TOKEN.transferFrom(msg.sender, address(this), totalAmount)) {
              revert InsufficientAllowanceOrBalance();
         }

        for (uint256 i = 0; i < amounts.length; ++i) {
             _podIdCounter.increment();
             uint256 podId = _podIdCounter.current();
             uint256 amount = amounts[i];
             uint256 duration = durationsInSeconds[i];
             uint256 lockTimestamp = block.timestamp;
             uint256 unlockTimestamp = lockTimestamp + duration;

             pods[podId] = TemporalPod({
                 locker: msg.sender,
                 amount: amount,
                 duration: duration,
                 lockTimestamp: lockTimestamp,
                 unlockTimestamp: unlockTimestamp,
                 status: PodStatus.Locked,
                 outcomeData: ""
             });

             _userPods[msg.sender].push(podId);

             emit ChrononsLocked(msg.sender, podId, amount, duration, unlockTimestamp);
        }
    }


    /**
     * @notice Increases the lock duration for an existing, active Pod owned by the caller.
     * @param podId The ID of the pod to extend.
     * @param additionalDurationInSeconds The additional duration to add to the lock.
     */
    function extendLockDuration(uint256 podId, uint256 additionalDurationInSeconds) external whenNotPaused {
        TemporalPod storage pod = pods[podId];
        if (pod.locker == address(0)) revert PodNotFound();
        if (pod.locker != msg.sender) revert PodNotOwned();
        if (pod.status != PodStatus.Locked) revert PodNotLocked();
         if (additionalDurationInSeconds == 0) revert InvalidDuration(); // Must extend by at least 1 sec

        uint256 newUnlockTimestamp = pod.unlockTimestamp + additionalDurationInSeconds;
        // Optional: Enforce max total duration relative to original lock or a global max?
        // Let's enforce a global max unlock time relative to the *current* time for simplicity.
         if (newUnlockTimestamp > block.timestamp + protocolParameters.maxLockDuration) {
            revert CannotExtendPastMaxDuration();
         }

        pod.duration += additionalDurationInSeconds; // Update total duration tracked
        pod.unlockTimestamp = newUnlockTimestamp;

        emit LockDurationExtended(podId, newUnlockTimestamp);
    }

    /**
     * @notice Triggers the outcome determination logic for a Pod whose lock duration has completed.
     * Can only be called by the pod owner and after the unlock timestamp.
     * @param podId The ID of the pod to unlock.
     */
    function unlockPod(uint256 podId) external nonReentrant whenNotPaused {
        TemporalPod storage pod = pods[podId];
        if (pod.locker == address(0)) revert PodNotFound();
        if (pod.locker != msg.sender) revert PodNotOwned();
        if (pod.status != PodStatus.Locked) revert PodNotLocked();
        if (block.timestamp < pod.unlockTimestamp) revert PodLockNotExpired();

        // Determine outcome and store it
        _determineUnlockOutcome(podId, pod.amount, pod.duration, pod.lockTimestamp);

        pod.status = PodStatus.Unlocked;
        // outcomeData is set by _determineUnlockOutcome

        // Emit event using the stored outcome data
        (uint8 outcomeType, uint256 value1, uint256 value2) = abi.decode(pod.outcomeData, (uint8, uint256, uint256));
        emit PodUnlocked(podId, msg.sender, outcomeType, value1, value2);
    }

    /**
     * @notice Unlocks multiple completed pods in a single transaction.
     * @param podIds An array of Pod IDs to unlock.
     */
    function batchUnlockPods(uint256[] memory podIds) external nonReentrant whenNotPaused {
         if (podIds.length == 0) revert BatchLengthMismatch();
         for(uint256 i = 0; i < podIds.length; ++i) {
             uint256 podId = podIds[i];
             TemporalPod storage pod = pods[podId];
             // Perform checks inside the loop to process valid pods and skip invalid ones gracefully (or revert on first error)
             // Reverting on first error is simpler for demonstration.
             if (pod.locker == address(0)) revert PodNotFound();
             if (pod.locker != msg.sender) revert PodNotOwned();
             if (pod.status != PodStatus.Locked) revert PodNotLocked();
             if (block.timestamp < pod.unlockTimestamp) revert PodLockNotExpired();

             _determineUnlockOutcome(podId, pod.amount, pod.duration, pod.lockTimestamp);
             pod.status = PodStatus.Unlocked;
             (uint8 outcomeType, uint256 value1, uint256 value2) = abi.decode(pod.outcomeData, (uint8, uint256, uint256));
             emit PodUnlocked(podId, msg.sender, outcomeType, value1, value2);
         }
    }

    /**
     * @notice Transfers the determined outcome (Chronons, Shards, Key) to the user
     * after a Pod has been unlocked.
     * @param podId The ID of the pod to claim.
     */
    function claimPodContents(uint256 podId) external nonReentrant whenNotPaused {
        TemporalPod storage pod = pods[podId];
        if (pod.locker == address(0)) revert PodNotFound();
        if (pod.locker != msg.sender) revert PodNotOwned();
        if (pod.status == PodStatus.Locked) revert PodLockNotExpired(); // Implicitly also checks if pod exists
        if (pod.status == PodStatus.Claimed) revert PodAlreadyClaimed();
        if (pod.status != PodStatus.Unlocked) revert PodNotUnlocked(); // Should be Unlocked state

        // Decode the stored outcome
        (uint8 outcomeType, uint256 value1, uint256 value2) = abi.decode(pod.outcomeData, (uint8, uint256, uint256));

        if (outcomeType == 0) { // Chronons
             uint256 returnAmount = value1;
             uint256 feeAmount = (returnAmount * protocolParameters.protocolFeePercent) / 10000;
             uint256 netReturn = returnAmount - feeAmount;

             if (netReturn > 0) {
                _transferChronons(msg.sender, netReturn);
             }
             if (feeAmount > 0) {
                 // Fees stay in the contract, marked for withdrawal by admin
             }
             emit PodContentsClaimed(podId, msg.sender, outcomeType, netReturn, feeAmount);

        } else if (outcomeType == 1) { // Shards
             uint256 shardAmount = value1;
             _mintSingularityShards(msg.sender, shardAmount);
             emit PodContentsClaimed(podId, msg.sender, outcomeType, shardAmount, 0);

        } else if (outcomeType == 2) { // Key
             uint256 keyId = value1;
             uint256 creationPodIdCheck = value2; // Should match podId, used for verification
             if (creationPodIdCheck != podId) revert InvalidState("Outcome Key ID mismatch");

             // Transfer ownership of the key to the user
             _safeMint(msg.sender, keyId); // Mints the key determined/created during unlock
             _userKeys[msg.sender].push(keyId); // Track key for user

             emit PodContentsClaimed(podId, msg.sender, outcomeType, keyId, 0);

        } else {
            revert InvalidState("Unknown outcome type");
        }

        pod.status = PodStatus.Claimed;
        // outcomeData is kept for historical record
    }

    /**
     * @notice Claims contents for multiple unlocked pods in a single transaction.
     * @param podIds An array of Pod IDs to claim.
     */
    function batchClaimPodContents(uint256[] memory podIds) external nonReentrant whenNotPaused {
         if (podIds.length == 0) revert BatchLengthMismatch();
         for(uint256 i = 0; i < podIds.length; ++i) {
             uint256 podId = podIds[i];
             TemporalPod storage pod = pods[podId];
              // Perform checks inside the loop
             if (pod.locker == address(0)) revert PodNotFound();
             if (pod.locker != msg.sender) revert PodNotOwned();
             if (pod.status == PodStatus.Locked) revert PodLockNotExpired();
             if (pod.status == PodStatus.Claimed) revert PodAlreadyClaimed();
             if (pod.status != PodStatus.Unlocked) revert PodNotUnlocked();

             // Decode the stored outcome
             (uint8 outcomeType, uint256 value1, uint256 value2) = abi.decode(pod.outcomeData, (uint8, uint256, uint256));

            if (outcomeType == 0) { // Chronons
                uint256 returnAmount = value1;
                uint256 feeAmount = (returnAmount * protocolParameters.protocolFeePercent) / 10000;
                uint256 netReturn = returnAmount - feeAmount;
                 if (netReturn > 0) {
                    _transferChronons(msg.sender, netReturn);
                 }
                 // Fees stay in contract
                 emit PodContentsClaimed(podId, msg.sender, outcomeType, netReturn, feeAmount);

            } else if (outcomeType == 1) { // Shards
                uint256 shardAmount = value1;
                _mintSingularityShards(msg.sender, shardAmount);
                emit PodContentsClaimed(podId, msg.sender, outcomeType, shardAmount, 0);

            } else if (outcomeType == 2) { // Key
                uint256 keyId = value1;
                uint256 creationPodIdCheck = value2;
                if (creationPodIdCheck != podId) revert InvalidState("Outcome Key ID mismatch");

                 _safeMint(msg.sender, keyId);
                 _userKeys[msg.sender].push(keyId);

                 emit PodContentsClaimed(podId, msg.sender, outcomeType, keyId, 0);
            } else {
                 revert InvalidState("Unknown outcome type in batch");
            }

             pod.status = PodStatus.Claimed;
         }
    }


    /**
     * @notice Spends Chronons to potentially modify properties of an owned Entropic Key.
     * Requires the user to have approved this contract to spend the Chronons.
     * @param keyId The ID of the Entropic Key to attune.
     * @param costChronons The amount of Chronons to spend for this attunement attempt. (Could make this fixed by params)
     */
    function attuneKey(uint256 keyId, uint256 costChronons) external nonReentrant whenNotPaused {
        if (_ownerOf(keyId) != msg.sender) revert KeyNotOwned();
        if (entropicKeyData[keyId].creationPodId == 0 && !_exists(keyId)) revert KeyNotFound(); // Check if key exists and is managed by protocol
        if (costChronons < protocolParameters.keyAttuneCostChronons) revert InvalidArgument("cost too low"); // Example gate

        // Transfer cost from user to contract
         if (!CHRONON_TOKEN.transferFrom(msg.sender, address(this), costChronons)) {
              revert InsufficientAllowanceOrBalance();
         }

        // --- Complex Attunement Logic ---
        // This logic is simplified for example; could be highly complex based on randomness, cost, key properties, etc.
        // Use randomness source (acknowledging blockchain randomness limitations)
        uint256 rand = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, tx.origin, keyId, costChronons, entropicKeyData[keyId].resonanceScore, entropicKeyData[keyId].colorState, block.number)));

        EntropicKeyData storage keyData = entropicKeyData[keyId];

        // Example: Increase resonance based on cost and randomness
        uint256 resonanceIncrease = (costChronons / protocolParameters.keyAttuneCostChronons) + (rand % 10); // Spend more = potentially higher increase + random bonus
        keyData.resonanceScore += resonanceIncrease;

        // Example: Change color state based on randomness
        keyData.colorState = uint8(rand % 256); // Randomly assign a new color state

        // More complex effects could include:
        // - Small chance to decrease score
        // - Small chance to yield a small amount of Shards back
        // - Conditional changes based on current state

        // Fees stay in contract
        emit KeyAttuned(msg.sender, keyId, keyData.resonanceScore, keyData.colorState);
    }

    /**
     * @notice Burns multiple owned Entropic Keys to potentially create a new one.
     * Requires the user to have approved this contract to spend the Chronons cost.
     * @param keyIds An array of Entropic Key IDs to combine. Requires length >= 2.
     * @return newKeyId The ID of the newly minted key, or 0 if combination failed to yield a new key.
     */
    function combineKeys(uint256[] memory keyIds) external nonReentrant whenNotPaused returns (uint256 newKeyId) {
        if (keyIds.length < 2) revert InvalidKeyCombination();

        // Check ownership for all keys and burn them
        for(uint256 i = 0; i < keyIds.length; ++i) {
            uint256 currentKeyId = keyIds[i];
            if (_ownerOf(currentKeyId) != msg.sender) revert KeyNotOwned();
            if (entropicKeyData[currentKeyId].creationPodId == 0 && !_exists(currentKeyId)) revert KeyNotFound(); // Ensure it's a protocol key and exists

            // Use the internal burn function
            _burnKey(currentKeyId); // This handles ERC721 burn and internal tracking removal
            // Note: entropicKeyData for burned keys is intentionally kept for historical record/provenance,
            // but no longer linked to an owner via ERC721.
        }

        // Transfer combination cost from user to contract
        if (!CHRONON_TOKEN.transferFrom(msg.sender, address(this), protocolParameters.keyCombineCostChronons)) {
             revert InsufficientAllowanceOrBalance();
        }

        // --- Complex Combination Logic ---
        // This logic is simplified; could involve averaging properties, random inheritance,
        // deterministic results based on specific combinations, or probability of failure.

        // Use randomness source
        bytes32 randomSeed = keccak256(abi.encodePacked(block.timestamp, block.difficulty, tx.origin, keyIds, block.number));
        uint256 rand = uint256(randomSeed);

        // Example Probability: 50% chance to get a new key + 5% chance per burned key over 2
        uint256 successProb = 5000 + ((keyIds.length - 2) * 500); // 5000 = 50%, 500 = 5% in basis points
        if (successProb > 10000) successProb = 10000; // Cap at 100%

        if (rand % 10000 < successProb) {
             // Combination successful, mint a new key
             _keyIdCounter.increment();
             newKeyId = _keyIdCounter.current();

             // Determine new key properties based on burned keys (Simplified)
             uint256 totalResonance = 0;
             uint256 avgColorState = 0;
             // Note: Need to access original entropicKeyData *before* burning if deriving from old properties
             // For simplicity, let's derive from a hash of burned key IDs and amount/duration (not ideal, but demonstrates concept)
             bytes32 derivedAttribute = keccak256(abi.encodePacked(keyIds, randomSeed));

             entropicKeyData[newKeyId] = EntropicKeyData({
                 creationPodId: 0, // Mark as created via combination, not a pod
                 resonanceScore: totalResonance + (rand % 100), // Start with some resonance
                 coreAttribute: derivedAttribute,
                 colorState: uint8(rand % 256)
             });

             // Mint the new key to the user
             _safeMint(msg.sender, newKeyId);
             _userKeys[msg.sender].push(newKeyId);

             emit KeysCombined(msg.sender, keyIds, newKeyId);
        } else {
             // Combination failed, keys are still burned, cost is paid.
             // Could optionally return a tiny amount of Chronons or Shards on failure.
             newKeyId = 0;
             emit KeysCombined(msg.sender, keyIds, 0); // Indicate failure with newKeyId 0
        }

        // Fees stay in contract
        // Attune & Combine costs could also be routed to the fee recipient instead of just staying in the contract.
        // For now, they remain in the contract's Chronon balance.

        return newKeyId;
    }

    /**
     * @notice Burns an owned Entropic Key, removing it from circulation.
     * @param keyId The ID of the Entropic Key to burn.
     */
    function burnKey(uint256 keyId) external nonReentrant whenNotPaused {
        if (_ownerOf(keyId) != msg.sender) revert KeyNotOwned();
        if (entropicKeyData[keyId].creationPodId == 0 && !_exists(keyId)) revert KeyNotFound(); // Ensure it's a protocol key and exists

        _burnKey(keyId);

        emit KeyBurned(msg.sender, keyId);
    }


    // --- View Functions ---

    /**
     * @notice Returns the current protocol parameters.
     */
    function getParameters() external view returns (ProtocolParameters memory) {
        return protocolParameters;
    }

     /**
     * @notice Returns the address designated to receive protocol fees.
     */
    function getProtocolFeeRecipient() external view returns (address) {
        return _protocolFeeRecipient;
    }

    /**
     * @notice Returns details of a specific Temporal Pod.
     * @param podId The ID of the pod.
     * @return pod The TemporalPod struct data.
     */
    function getPod(uint256 podId) external view returns (TemporalPod memory pod) {
        pod = pods[podId];
        if (pod.locker == address(0) && podId > 0 && podId <= _podIdCounter.current()) {
            // Handle edge case for pod 0 or non-existent pods gracefully
            revert PodNotFound();
        }
    }

    /**
     * @notice Returns an array of Temporal Pod IDs owned by a user.
     * Note: This array is appended to; checking pod status is required
     * to see if a pod is still relevant (locked/unlocked/claimed).
     * @param user The address of the user.
     * @return podIds An array of Pod IDs.
     */
    function getUserPods(address user) external view returns (uint256[] memory) {
        return _userPods[user];
    }

     /**
     * @notice Returns the dynamic data associated with an Entropic Key NFT.
     * @param keyId The ID of the key.
     * @return keyData The EntropicKeyData struct data.
     */
    function getKeyData(uint256 keyId) external view returns (EntropicKeyData memory keyData) {
        keyData = entropicKeyData[keyId];
        // Can add a check if the key exists via ERC721 enumerable or _exists
         if (keyData.creationPodId == 0 && !_exists(keyId)) { // Assuming combination keys have creationPodId 0
            revert KeyNotFound();
         }
    }

    /**
     * @notice Returns an array of Entropic Key IDs owned by a user, tracked by the protocol.
     * Note: ERC721Enumerable offers a standard way to get keys by owner index,
     * but this provides a protocol-specific list which might include keys
     * temporarily held by the protocol (e.g., during batch operations, though not implemented here).
     * For simplicity, this list is populated on mint.
     * @param user The address of the user.
     * @return keyIds An array of Key IDs.
     */
    function getUserKeys(address user) external view returns (uint256[] memory) {
        // Standard ERC721Enumerable approach is generally preferred for true ownership
        // This _userKeys mapping is illustrative of how protocol could track its own state.
        // Let's return the internal one for this example.
        return _userKeys[user];
    }


    /**
     * @notice Returns the total number of Temporal Pods ever created.
     */
    function getTotalPods() external view returns (uint256) {
        return _podIdCounter.current();
    }

     /**
     * @notice Returns the total number of Entropic Keys ever minted by the protocol.
     */
    function getTotalKeys() external view returns (uint256) {
        return _keyIdCounter.current();
    }

    /**
     * @notice Returns the contract's current balance of Chronon tokens.
     * Includes locked, unlocked (unclaimed), and fee Chronons.
     */
    function getProtocolChrononBalance() external view returns (uint256) {
        return CHRONON_TOKEN.balanceOf(address(this));
    }

     /**
     * @notice Returns the contract's current balance of Singularity Shard tokens.
     */
    function getProtocolShardBalance() external view returns (uint256) {
        return SINGULARITY_SHARD_TOKEN.balanceOf(address(this));
    }


    // --- Internal Functions ---

    /**
     * @notice Determines the probabilistic outcome of unlocking a pod.
     * Called by `unlockPod`. Stores the outcome in `pod.outcomeData`.
     * Uses a pseudo-random source (block hash, timestamp, etc.).
     * @param podId The ID of the pod being unlocked.
     * @param amount The amount of Chronons locked.
     * @param duration The lock duration.
     * @param lockTimestamp The timestamp when the pod was locked.
     */
    function _determineUnlockOutcome(uint256 podId, uint256 amount, uint256 duration, uint256 lockTimestamp) internal {
        // --- Pseudo-Randomness Source ---
        // WARNING: block.timestamp, block.difficulty/basefee, tx.origin can be manipulated
        // by miners/validators in low-difficulty scenarios. For real-world, high-value dApps,
        // use Chainlink VRF or similar verifiable randomness solutions.
        // This is used for demonstration purposes only.
        bytes32 randomSeed = keccak256(abi.encodePacked(
            block.timestamp,
            block.difficulty, // Or block.basefee in PoS
            tx.origin,
            podId,
            amount,
            duration,
            lockTimestamp,
            _podIdCounter.current(), // Add protocol state entropy
            _keyIdCounter.current(),
            msg.sender // Add user entropy
        ));

        uint256 rand = uint256(randomSeed);
        uint256 outcomeRoll = rand % 10000; // Roll a number between 0 and 9999

        // --- Outcome Probability Calculation ---
        uint256 durationInDays = duration / 1 days; // Simplified duration measure
        uint256 amountInThousands = amount / 1000; // Simplified amount measure (handle token decimals if needed)

        // Calculate boosted probabilities in basis points
        uint256 keyProbBoost = durationInDays * protocolParameters.keyProbMultiplierPerDay;
        uint256 shardProbBoost = amountInThousands * protocolParameters.shardProbMultiplierPer1000Chronons;

        // Base chance is for Chronon return. Key/Shard chances boost *away* from Chronon chance.
        uint256 keyChance = keyProbBoost; // Initial chance for Key
        uint256 shardChance = shardProbBoost; // Initial chance for Shard

        // Ensure probabilities don't exceed 100% combined
        uint256 totalBoost = keyChance + shardChance;
        if (totalBoost > 10000) {
            uint256 excess = totalBoost - 10000;
            // Proportionally reduce boost if over 100%
            keyChance = (keyChance * (10000 - excess / 2)) / 10000; // Simple reduction
            shardChance = (shardChance * (10000 - excess / 2)) / 10000;
            // Clamp again just in case
            if (keyChance + shardChance > 10000) {
                 uint256 totalCurrent = keyChance + shardChance;
                 keyChance = (keyChance * 10000) / totalCurrent;
                 shardChance = (shardChance * 10000) / totalCurrent;
            }
        }

        uint256 chrononChance = 10000 - keyChance - shardChance;
        // Adjust chronon chance based on the base probability, ensuring it's at least the base unless boosted chances are very high
        if (chrononChance < protocolParameters.outcomeProbBasePoint) {
             chrononChance = protocolParameters.outcomeProbBasePoint;
             // Re-normalize if Chronon chance was boosted to minimum, but total is still > 10000 (shouldn't happen with logic above)
             if (chrononChance + keyChance + shardChance > 10000) {
                 uint256 totalCurrent = chrononChance + keyChance + shardChance;
                 chrononChance = (chrononChance * 10000) / totalCurrent;
                 keyChance = (keyChance * 10000) / totalCurrent;
                 shardChance = (shardChance * 10000) / totalCurrent;
             }
        }


        // --- Determine Outcome Based on Roll ---
        uint8 outcomeType;
        uint256 value1;
        uint256 value2; // For Key ID + creation pod verification

        if (outcomeRoll < keyChance) {
            // Outcome: Entropic Key
            outcomeType = 2;
            // Mint the key internally *now* but delay transfer until claim
            uint256 newKeyId = _mintEntropicKey(address(this), podId, amount, duration, lockTimestamp); // Mint to contract temporarily
            value1 = newKeyId;
            value2 = podId; // Store original podId for verification on claim

        } else if (outcomeRoll < keyChance + shardChance) {
            // Outcome: Singularity Shards
            outcomeType = 1;
            // Amount of shards could be based on amount locked, duration, or random
            uint256 shardAmount = amount / 100 + (rand % 100); // Example: 1% of Chronons + small random bonus
            if (shardAmount == 0) shardAmount = 1; // Minimum 1 shard
            value1 = shardAmount;
            value2 = 0;

        } else {
            // Outcome: Chronons Return (Base Case)
            outcomeType = 0;
            // Return amount could be original amount, or original amount minus a burn/sink percentage, or even more on rare rolls
            uint256 returnAmount = amount; // Simple: return original amount before fee
            value1 = returnAmount;
            value2 = 0;
        }

        // Store the outcome data in the pod
        pods[podId].outcomeData = abi.encode(outcomeType, value1, value2);
    }

    /**
     * @notice Internal function to handle Singularity Shard distribution.
     * Placeholder - assumes ISingularityShard has a minting function available
     * to this contract or assumes contract holds a pool of shards to transfer.
     * In a real system, this would interact with the Shard token's specific logic (minting/transferring).
     * @param recipient The address to send the shards to.
     * @param amount The amount of shards.
     */
    function _mintSingularityShards(address recipient, uint256 amount) internal {
        // Example: Assume SingularityShard is an ERC20 and this contract holds a pool
        // In a real dApp, if Shards are minted, the ISingularityShard interface/contract
        // would need a 'mint' function callable by this protocol contract (e.g., via MinterRole).
        // For this example, we'll just perform a transfer, assuming the contract holds enough Shards.
        if (amount > 0) {
             // Check contract balance and transfer
             uint256 contractBalance = SINGULARITY_SHARD_TOKEN.balanceOf(address(this));
             if (contractBalance < amount) {
                 // This indicates an issue with the protocol's Shard management or supply.
                 // For this example, we'll revert. In a real scenario, perhaps log an error
                 // or handle it differently (e.g., queue for manual shard top-up).
                 revert InsufficientProtocolBalance("SingularityShard", contractBalance, amount); // Custom error not defined, using generic
             }
             SINGULARITY_SHARD_TOKEN.transfer(recipient, amount);
        }
    }

    /**
     * @notice Internal function to mint an Entropic Key NFT and initialize its dynamic data.
     * Called by `_determineUnlockOutcome` or `combineKeys`.
     * @param recipient The address that will eventually own the key.
     * @param podId The ID of the pod that created it (0 if from combination).
     * @param amount The amount from the creating pod (0 if from combination).
     * @param duration The duration from the creating pod (0 if from combination).
     * @param lockTimestamp The lock timestamp from the creating pod (0 if from combination).
     * @return keyId The ID of the newly minted key.
     */
    function _mintEntropicKey(address recipient, uint256 podId, uint256 amount, uint256 duration, uint256 lockTimestamp) internal returns (uint256 keyId) {
        _keyIdCounter.increment();
        keyId = _keyIdCounter.current();

        // --- Initial Key Data Calculation ---
        // Properties are derived from the parameters that created it (or combination inputs)
        // This is where the "dynamic" and "unique" aspects come in.

        bytes32 coreAttributeSeed = keccak256(abi.encodePacked(podId, amount, duration, lockTimestamp, recipient));
        uint256 randForProps = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, keyId, coreAttributeSeed)));

        entropicKeyData[keyId] = EntropicKeyData({
            creationPodId: podId,
            resonanceScore: uint256(randForProps % 100), // Start with random base resonance
            coreAttribute: coreAttributeSeed, // Example: Hash of creation params
            colorState: uint8(randForProps % 256) // Example: Random initial color state
            // Add more derived properties here
        });

        // Mint the ERC721 token. Note: _safeMint handles ownership transfer to `recipient`
        // If called from _determineUnlockOutcome, recipient is `address(this)`.
        // If called from combineKeys, recipient is `msg.sender`.
        _safeMint(recipient, keyId);

        // Add to user's key list *if* minted directly to user (e.g., from combineKeys)
        // If minted to contract (from unlock), it's added to user list during `claimPodContents`.
        if (recipient != address(this)) {
             _userKeys[recipient].push(keyId);
        }

        // No event here, main event is KeyAttuned/KeysCombined or PodContentsClaimed
        // depending on the flow.
    }

    /**
     * @notice Internal function to burn an Entropic Key NFT and remove protocol tracking.
     * @param keyId The ID of the key to burn.
     */
    function _burnKey(uint256 keyId) internal {
         address owner = _ownerOf(keyId);
         if (owner == address(0)) return; // Already burned or doesn't exist

        // Remove from protocol's user key tracking list (basic implementation)
        // Finding and removing from a dynamic array is gas intensive.
        // For production, a more efficient tracking method would be needed.
        uint256[] storage userKeys = _userKeys[owner];
        for (uint256 i = 0; i < userKeys.length; ++i) {
            if (userKeys[i] == keyId) {
                userKeys[i] = userKeys[userKeys.length - 1];
                userKeys.pop();
                break;
            }
        }

        // Burn the ERC721 token
        _burn(keyId);
        // entropicKeyData[keyId] remains for provenance
    }


    /**
     * @notice Internal function to handle Chronon transfers securely.
     * Abstracted for potential future reentrancy guards or specific logic.
     * @param recipient The address to send the tokens to.
     * @param amount The amount of Chronons to transfer.
     */
    function _transferChronons(address recipient, uint256 amount) internal {
        if (amount > 0 && recipient != address(0)) {
            // Using SafeERC20 is recommended for production
            CHRONON_TOKEN.transfer(recipient, amount);
        }
    }

    // --- ERC721 Overrides ---

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     * Generates a placeholder URI for the Entropic Keys. In a real dApp, this would
     * point to an API or IPFS where the metadata JSON is hosted, likely generated
     * dynamically based on the EntropicKeyData struct.
     */
    function tokenURI(uint256 keyId) public view override returns (string memory) {
         if (!_exists(keyId)) {
             revert ERC721NonexistentToken(keyId); // Use OZ error
         }

         // Placeholder: In reality, fetch data from entropicKeyData[keyId]
         // and construct a JSON string or a URL pointing to the JSON.
         // Example: return string(abi.encodePacked("ipfs://<base_uri>/", Strings.toString(keyId), ".json"));
         // For demonstration, return a simple string indicating data is internal.
         EntropicKeyData memory keyData = entropicKeyData[keyId];
         string memory baseURI = "data:application/json;base64,";
         bytes memory json = abi.encodePacked(
             '{"name": "Entropic Key #', Strings.toString(keyId), '", ',
             '"description": "A unique key from the QuantumLeap Protocol.", ',
             '"attributes": [',
                 '{"trait_type": "Creation Pod", "value": ', Strings.toString(keyData.creationPodId), '},',
                 '{"trait_type": "Resonance Score", "value": ', Strings.toString(keyData.resonanceScore), '},',
                 '{"trait_type": "Core Attribute (Hash)", "value": "', Strings.toHexString(uint256(keyData.coreAttribute)), '"},',
                 '{"trait_type": "Color State", "value": ', Strings.toString(keyData.colorState), '}',
             ']}'
         );
        // Using Base64 for data URI requires importing Base64 encoding utility
        // import "@openzeppelin/contracts/utils/Base64.sol";
        // return string(abi.encodePacked(baseURI, Base64.encode(json)));
        // Sticking to simple string for minimal imports in this example.
        return string(abi.encodePacked(baseURI, "{...}")); // Indicate metadata exists but is complex

     }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        // Also supports ERC721Enumerable if imported
        return interfaceId == type(IERC721).interfaceId ||
               interfaceId == type(IERC165).interfaceId ||
               super.supportsInterface(interfaceId);
    }

    // Helper function for custom errors (used above)
    // function InvalidArgument(string memory message) internal pure {} // Placeholder if not using OZ generic

}
```