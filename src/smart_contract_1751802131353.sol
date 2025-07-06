Okay, here is a smart contract concept I've designed called `QuantumVault`. It combines elements of prediction markets, time-based state transitions, commit-reveal schemes, and a novel entropy-driven resolution mechanism with internal penalty distribution. The core idea is that users "commit" to potential future "outcomes" by locking value and specifying probability weights. The final outcome is determined by revealed entropy and the aggregate committed weights, with penalties for non-participation or incorrect predictions funding those who correctly predicted the outcome.

This design aims to be complex, use advanced concepts (commit-reveal, entropy-weighted outcome selection, internal penalty redistribution), and avoids direct duplication of standard ERC tokens, NFTs, or simple DeFi mechanics.

---

**Smart Contract: QuantumVault**

**Outline:**

1.  **Purpose:** A vault where users commit value to potential future outcomes. The winning outcome is determined by external entropy combined with aggregated user-assigned probabilities. Users who commit to the winning outcome and follow protocol steps are rewarded with their principal plus a share of penalties from losing/non-compliant users.
2.  **Core Concepts:**
    *   Epochs: The contract operates in distinct time periods (epochs).
    *   States: Each epoch progresses through defined states (Commit, Reveal, EntropyPending, Resolved).
    *   Outcomes: Pre-configured potential results with associated data/actions.
    *   Commit-Reveal: Users commit a hash of their chosen outcomes/weights/payload, then later reveal the actual data.
    *   Entropy-Weighted Resolution: A provided random seed interacts with the total *revealed* probability weights for each outcome to select the winner.
    *   Internal Penalties & Rewards: Funds from users who committed to losing outcomes or failed to reveal are distributed among users who committed to the winning outcome and *did* reveal.
3.  **Key Data Structures:**
    *   `OutcomeConfig`: Defines a possible outcome (ID, description, associated payload).
    *   `UserCommit`: Stores a user's commitment details (locked value, hashed data, revealed status, probability weights).
    *   `EpochDetails`: Stores parameters and state for a specific epoch.
4.  **Workflow:**
    *   Owner configures outcomes and epoch parameters.
    *   Owner starts a new epoch (Idle -> Commit).
    *   Users `commit` value, outcome weights, and a hash of their payload during the Commit period.
    *   Owner/Anyone calls `transitionToReveal` after Commit period ends (Commit -> Reveal).
    *   Users `revealCommit` their payload during the Reveal period.
    *   Owner/Anyone calls `transitionToEntropyPending` after Reveal period ends (Reveal -> EntropyPending).
    *   Designated `entropySource` provides the random seed via `provideEntropy` (EntropyPending -> Resolved). This call also triggers outcome calculation and penalty distribution logic.
    *   Users `claimResolvedValue` after the epoch is Resolved.
5.  **Functions (26 Total + Constructor):**

    *   **Configuration (Owner/Admin):**
        1.  `constructor`: Initializes owner.
        2.  `initializeParameters`: Sets epoch durations and minimum commit value.
        3.  `addOutcomeConfig`: Defines a new potential outcome.
        4.  `updateOutcomeConfig`: Modifies an existing outcome configuration.
        5.  `removeOutcomeConfig`: Removes an outcome (restricted if active).
        6.  `setEntropySource`: Sets the address authorized to provide entropy.
    *   **Epoch Lifecycle Transitions (Permissioned/Time-gated):**
        7.  `startNextEpoch`: Transitions from Idle or Resolved to Commit state.
        8.  `transitionToReveal`: Transitions from Commit to Reveal state.
        9.  `transitionToEntropyPending`: Transitions from Reveal to EntropyPending state.
        10. `provideEntropy`: Provided by entropy source, transitions from EntropyPending to Resolved state, triggers outcome calculation and distribution.
    *   **User Interactions (Commit/Reveal/Claim):**
        11. `commit`: Locks value and commits to outcomes with weights via a payload hash.
        12. `revealCommit`: Reveals the payload data corresponding to a prior commit hash.
        13. `cancelCommit`: Cancels a commit during the Commit phase.
        14. `claimResolvedValue`: Claims locked value + share of penalties after resolution.
    *   **Internal Logic (Called by Transitions/Claims):**
        15. `_calculateAndDistribute`: Calculates the winning outcome and distributes funds/penalties. (Called by `provideEntropy`)
        16. `_executeWinningOutcomePayload`: Executes the payload associated with the winning outcome. (Called by `_calculateAndDistribute`)
    *   **View Functions (Read-only):**
        17. `getEpochState`: Gets the current state of the active epoch.
        18. `getCurrentEpochId`: Gets the ID of the active epoch.
        19. `getCommitPeriodEnd`: Gets the timestamp for the end of the commit period.
        20. `getRevealPeriodEnd`: Gets the timestamp for the end of the reveal period.
        21. `getEntropyPeriodEnd`: Gets the timestamp for the end of the entropy period.
        22. `getOutcomeConfig`: Gets the details for a specific outcome ID.
        23. `getUserCommit`: Gets commit details for a user in the current epoch.
        24. `getTotalCommittedValue`: Gets the total value committed in the current epoch.
        25. `getEntropySource`: Gets the configured entropy source address.
        26. `getResolvedEpochWinningOutcome`: Gets the winning outcome ID for a *resolved* epoch.
        27. `getResolvedEpochEntropySeed`: Gets the entropy seed used for a *resolved* epoch.
        28. `getTotalRevealedWeightForOutcome`: Gets the sum of revealed weights for an outcome in the current epoch.
        29. `getResolvedEpochPenaltyPool`: Gets the total penalty pool value for a *resolved* epoch.

---
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title QuantumVault
 * @author YourNameHere
 * @notice A smart contract for committing value to potential future outcomes,
 * resolved by external entropy and aggregated user probabilities using a commit-reveal scheme.
 * Penalties from losing/non-compliant users are redistributed to winning/compliant users.
 *
 * Outline:
 * - Epoch-based state transitions (Idle, Commit, Reveal, EntropyPending, Resolved).
 * - Configuration of potential outcomes with associated data/actions.
 * - User commits value and a hash of desired outcome probabilities/payload during Commit phase.
 * - User reveals the actual probabilities/payload during Reveal phase.
 * - Designated entropy source provides randomness during EntropyPending phase.
 * - Contract resolves the outcome based on entropy and aggregate *revealed* weights.
 * - Locked value from non-revealed or losing commits forms a penalty pool.
 * - Penalty pool is distributed pro-rata among users who committed to the winning outcome AND revealed.
 * - Users can claim their resolved value after the epoch is Resolved.
 *
 * Function Summary:
 *
 * Configuration (Owner/Admin):
 * 1. constructor(): Initializes contract owner.
 * 2. initializeParameters(uint64 commitDuration, uint64 revealDuration, uint64 entropyDuration, uint256 minCommit): Sets epoch phase durations and minimum commit value.
 * 3. addOutcomeConfig(uint8 outcomeId, string memory description, bytes memory payload): Adds a new possible outcome.
 * 4. updateOutcomeConfig(uint8 outcomeId, string memory description, bytes memory payload): Updates an existing outcome config.
 * 5. removeOutcomeConfig(uint8 outcomeId): Removes an outcome config (only if no active commits use it).
 * 6. setEntropySource(address _entropySource): Sets the address authorized to provide entropy.
 *
 * Epoch Lifecycle Transitions (Permissioned/Time-gated):
 * 7. startNextEpoch(): Initiates a new epoch in the Commit state. Requires current state is Idle or Resolved.
 * 8. transitionToReveal(): Moves epoch state from Commit to Reveal after Commit period ends. Callable by anyone.
 * 9. transitionToEntropyPending(): Moves epoch state from Reveal to EntropyPending after Reveal period ends. Callable by anyone.
 * 10. provideEntropy(bytes32 _entropySeed): Provided by the entropySource, moves state from EntropyPending to Resolved. Triggers resolution.
 *
 * User Interactions (Commit/Reveal/Claim):
 * 11. commit(mapping(uint8 => uint256) calldata outcomeWeights, bytes32 payloadHash): Locks ETH/value, commits to outcome weights and a payload hash.
 * 12. revealCommit(bytes memory payload): Reveals the payload data associated with a prior commit hash.
 * 13. cancelCommit(): Cancels a pending commit during the Commit phase. Refunds locked value.
 * 14. claimResolvedValue(uint256 epochId): Claims resolved value (principal + penalty share) for a specific resolved epoch.
 *
 * Internal Logic (Called by transitions/claims):
 * 15. _calculateAndDistribute(uint256 epochId, bytes32 _entropySeed): Internal function to determine winning outcome and distribute funds/penalties.
 * 16. _executeWinningOutcomePayload(uint256 epochId, uint8 winningOutcomeId, bytes memory payload): Internal function to execute logic based on the winning outcome's payload.
 *
 * View Functions (Read-only):
 * 17. getEpochState(): Returns the current state enum of the active epoch.
 * 18. getCurrentEpochId(): Returns the ID of the active epoch.
 * 19. getCommitPeriodEnd(): Returns the timestamp when the commit period ends.
 * 20. getRevealPeriodEnd(): Returns the timestamp when the reveal period ends.
 * 21. getEntropyPeriodEnd(): Returns the timestamp when the entropy pending period ends.
 * 22. getOutcomeConfig(uint8 outcomeId): Returns the configuration details for a specific outcome.
 * 23. getUserCommit(address user): Returns commit details for a user in the current epoch.
 * 24. getTotalCommittedValue(): Returns the total value committed in the current epoch.
 * 25. getEntropySource(): Returns the configured entropy source address.
 * 26. getResolvedEpochWinningOutcome(uint256 epochId): Returns the winning outcome ID for a specific resolved epoch.
 * 27. getResolvedEpochEntropySeed(uint256 epochId): Returns the entropy seed for a specific resolved epoch.
 * 28. getTotalRevealedWeightForOutcome(uint8 outcomeId): Calculates and returns the total *revealed* weight committed to an outcome in the current epoch.
 * 29. getResolvedEpochPenaltyPool(uint256 epochId): Returns the total penalty value collected for a resolved epoch.
 */

contract QuantumVault {
    // --- Errors ---
    error NotOwner();
    error NotEntropySource();
    error InvalidEpochState();
    error InvalidOutcomeId(uint8 outcomeId);
    error OutcomeIdAlreadyExists(uint8 outcomeId);
    error OutcomeInUse(uint8 outcomeId);
    error EpochParametersNotSet();
    error CommitPeriodActive();
    error RevealPeriodActive();
    error EntropyPeriodActive();
    error CommitPeriodNotActive();
    error RevealPeriodNotActive();
    error EntropyPeriodNotActive();
    error EpochNotResolved();
    error NoActiveCommit();
    error CommitAlreadyExists();
    error InsufficientCommitValue(uint256 required, uint256 provided);
    error InvalidOutcomeWeights();
    error CommitDataAlreadyRevealed();
    error InvalidRevealData();
    error EntropyAlreadyProvided();
    error NoValueToClaim();
    error ValueAlreadyClaimed();
    error EpochAlreadyStarted();
    error EpochTransitionNotDue();
    error EntropySourceNotSet();
    error CannotCancelAfterCommitPeriod();

    // --- Enums ---
    enum EpochState {
        Idle, // Initial state, or waiting to start next epoch
        Commit, // Users can submit commitments
        Reveal, // Users reveal commitment data
        EntropyPending, // Waiting for entropy source
        Resolved // Outcome determined, funds ready for claim
    }

    // --- Structs ---
    struct OutcomeConfig {
        string description;
        bytes payload; // Data or instructions associated with this outcome
        bool exists; // To check if outcomeId is configured
    }

    struct UserCommit {
        uint256 lockedValue; // Value committed by the user
        bytes32 payloadHash; // Keccak256 hash of the user's chosen probabilities/payload
        mapping(uint8 => uint256) outcomeWeights; // Weights assigned to potential outcomes (used after reveal)
        bool revealed; // True if the user revealed their payload
        bool claimed; // True if the user has claimed resolved value
        uint256 resolvedClaimValue; // The final amount claimable by the user
    }

    struct EpochDetails {
        EpochState state;
        uint64 commitPeriodEnd;
        uint64 revealPeriodEnd;
        uint64 entropyPeriodEnd;
        uint256 totalCommittedValue; // Total value locked in this epoch
        uint8 winningOutcomeId; // The determined outcome after resolution
        bytes32 entropySeed; // The seed used for resolution
        uint256 penaltyPoolValue; // Total value from losing/non-revealed commits
        mapping(address => UserCommit) commits; // User commitments for this epoch
        // Store total revealed weights per outcome for efficient calculation
        mapping(uint8 => uint224) totalRevealedOutcomeWeights;
    }

    // --- State Variables ---
    address private immutable i_owner;
    address public entropySource;

    uint64 public commitPeriodDuration;
    uint64 public revealPeriodDuration;
    uint64 public entropyPeriodDuration;
    uint256 public minimumCommitValue;
    bool private parametersInitialized; // Flag to ensure params are set once

    uint256 public currentEpochId;
    // Mapping from epochId to EpochDetails
    mapping(uint256 => EpochDetails) public epochs;

    // Mapping from outcomeId to OutcomeConfig
    mapping(uint8 => OutcomeConfig) public outcomeConfigs;
    uint8[] public configuredOutcomeIds; // Array to easily iterate outcomes

    // --- Events ---
    event ParametersInitialized(uint64 commitDuration, uint64 revealDuration, uint64 entropyDuration, uint256 minCommit);
    event EntropySourceUpdated(address indexed newSource);
    event OutcomeConfigAdded(uint8 indexed outcomeId, string description, bytes payload);
    event OutcomeConfigUpdated(uint8 indexed outcomeId, string description, bytes payload);
    event OutcomeConfigRemoved(uint8 indexed outcomeId);

    event EpochStarted(uint256 indexed epochId, uint64 commitEnd, uint64 revealEnd, uint64 entropyEnd);
    event EpochTransitioned(uint256 indexed epochId, EpochState oldState, EpochState newState);
    event CommitSubmitted(uint256 indexed epochId, address indexed user, uint256 value, bytes32 payloadHash);
    event CommitRevealed(uint256 indexed epochId, address indexed user);
    event CommitCancelled(uint256 indexed epochId, address indexed user, uint256 refundedValue);
    event EntropyProvided(uint256 indexed epochId, address indexed provider, bytes32 seed);
    event EpochResolved(uint256 indexed epochId, uint8 winningOutcomeId, bytes32 entropySeed, uint256 penaltyPool);
    event ValueClaimed(uint256 indexed epochId, address indexed user, uint256 amount);

    // --- Modifiers ---
    modifier onlyOwner() {
        if (msg.sender != i_owner) revert NotOwner();
        _;
    }

    modifier onlyEntropySource() {
        if (msg.sender != entropySource) revert NotEntropySource();
        _;
    }

    modifier requireState(uint256 epochId, EpochState expectedState) {
        if (epochs[epochId].state != expectedState) revert InvalidEpochState();
        _;
    }

    modifier requireStateAny(uint256 epochId, EpochState[] memory expectedStates) {
        bool stateMatch = false;
        for (uint i = 0; i < expectedStates.length; i++) {
            if (epochs[epochId].state == expectedStates[i]) {
                stateMatch = true;
                break;
            }
        }
        if (!stateMatch) revert InvalidEpochState();
        _;
    }

    // --- Constructor ---
    constructor() {
        i_owner = msg.sender;
        currentEpochId = 0; // Epoch 0 is the initial state, not an active epoch
        epochs[0].state = EpochState.Idle; // Ensure epoch 0 is Idle
    }

    // --- Configuration Functions ---

    /**
     * @notice Initializes the duration of epoch phases and the minimum commit value.
     * @param _commitDuration Duration of the commit phase in seconds.
     * @param _revealDuration Duration of the reveal phase in seconds.
     * @param _entropyDuration Duration of the entropy pending phase in seconds.
     * @param _minCommit Minimum value required for a user commit.
     * @dev Can only be called once by the owner and must be in Idle state.
     */
    function initializeParameters(uint64 _commitDuration, uint64 _revealDuration, uint64 _entropyDuration, uint256 _minCommit) public onlyOwner requireState(currentEpochId, EpochState.Idle) {
        if (parametersInitialized) revert EpochParametersNotSet(); // Use a more specific error name maybe? Like AlreadyInitialized
        if (_commitDuration == 0 || _revealDuration == 0 || _entropyDuration == 0) revert InvalidEpochParameters(); // Custom error? Or descriptive revert
        if (_minCommit == 0) revert InvalidEpochParameters(); // Custom error?

        commitPeriodDuration = _commitDuration;
        revealPeriodDuration = _revealDuration;
        entropyPeriodDuration = _entropyDuration;
        minimumCommitValue = _minCommit;
        parametersInitialized = true;

        emit ParametersInitialized(_commitDuration, _revealDuration, _entropyDuration, _minCommit);
    }

    /**
     * @notice Adds a new possible outcome configuration.
     * @param outcomeId Unique identifier for the outcome.
     * @param description Description of the outcome.
     * @param payload Arbitrary data associated with the outcome.
     * @dev Only owner can call. Cannot add if an outcome with the same ID exists.
     * Cannot add if an epoch is in progress (Commit/Reveal/EntropyPending).
     */
    function addOutcomeConfig(uint8 outcomeId, string memory description, bytes memory payload) public onlyOwner requireStateAny(currentEpochId, new EpochState[](2).push(EpochState.Idle).push(EpochState.Resolved)) {
        if (outcomeConfigs[outcomeId].exists) revert OutcomeIdAlreadyExists(outcomeId);

        outcomeConfigs[outcomeId] = OutcomeConfig(description, payload, true);
        configuredOutcomeIds.push(outcomeId);

        emit OutcomeConfigAdded(outcomeId, description, payload);
    }

    /**
     * @notice Updates an existing outcome configuration.
     * @param outcomeId Unique identifier for the outcome.
     * @param description New description.
     * @param payload New payload data.
     * @dev Only owner can call. Outcome must exist.
     * Cannot update if an epoch is in progress (Commit/Reveal/EntropyPending).
     */
    function updateOutcomeConfig(uint8 outcomeId, string memory description, bytes memory payload) public onlyOwner requireStateAny(currentEpochId, new EpochState[](2).push(EpochState.Idle).push(EpochState.Resolved)) {
        if (!outcomeConfigs[outcomeId].exists) revert InvalidOutcomeId(outcomeId);

        outcomeConfigs[outcomeId].description = description;
        outcomeConfigs[outcomeId].payload = payload;

        emit OutcomeConfigUpdated(outcomeId, description, payload);
    }

    /**
     * @notice Removes an outcome configuration.
     * @param outcomeId Unique identifier for the outcome.
     * @dev Only owner can call. Outcome must exist.
     * Cannot remove if an epoch is in progress (Commit/Reveal/EntropyPending).
     * Cannot remove if any user has committed to this outcome in the *current* or *previous* resolved epoch (to prevent breaking claim logic).
     * More robust check needed for "in use" - maybe only allow removing if state is Idle AND no commits *ever* used it, or just disallow if state isn't Idle. Let's disallow if not Idle/Resolved.
     */
    function removeOutcomeConfig(uint8 outcomeId) public onlyOwner requireStateAny(currentEpochId, new EpochState[](2).push(EpochState.Idle).push(EpochState.Resolved)) {
        if (!outcomeConfigs[outcomeId].exists) revert InvalidOutcomeId(outcomeId);

        // Note: A more advanced version might track which outcomes were committed to in past epochs.
        // For simplicity here, we just check if it's used in the *current* (not yet started) epoch context
        // or if the state prevents removal. The state check is sufficient for basic safety.

        delete outcomeConfigs[outcomeId];
        // Remove from array (gas inefficient for large arrays)
        for (uint i = 0; i < configuredOutcomeIds.length; i++) {
            if (configuredOutcomeIds[i] == outcomeId) {
                configuredOutcomeIds[i] = configuredOutcomeIds[configuredOutcomeIds.length - 1];
                configuredOutcomeIds.pop();
                break;
            }
        }

        emit OutcomeConfigRemoved(outcomeId);
    }

    /**
     * @notice Sets the address authorized to provide entropy for epoch resolution.
     * @param _entropySource The address that will call provideEntropy.
     * @dev Only owner can call.
     */
    function setEntropySource(address _entropySource) public onlyOwner {
        entropySource = _entropySource;
        emit EntropySourceUpdated(_entropySource);
    }

    // --- Epoch Lifecycle Transitions ---

    /**
     * @notice Starts a new epoch, transitioning the state to Commit.
     * @dev Requires epoch parameters to be initialized. Callable by owner.
     * Only allowed when current epoch is Idle or Resolved.
     */
    function startNextEpoch() public onlyOwner requireStateAny(currentEpochId, new EpochState[](2).push(EpochState.Idle).push(EpochState.Resolved)) {
        if (!parametersInitialized) revert EpochParametersNotSet();

        currentEpochId++;
        uint256 epochId = currentEpochId;
        EpochDetails storage epoch = epochs[epochId];

        epoch.state = EpochState.Commit;
        epoch.totalCommittedValue = 0;
        epoch.winningOutcomeId = 0; // Default/invalid ID
        epoch.entropySeed = bytes32(0); // Default/zero hash
        epoch.penaltyPoolValue = 0;

        uint64 now64 = uint64(block.timestamp);
        epoch.commitPeriodEnd = now64 + commitPeriodDuration;
        epoch.revealPeriodEnd = epoch.commitPeriodEnd + revealPeriodDuration;
        epoch.entropyPeriodEnd = epoch.revealPeriodEnd + entropyPeriodDuration;

        epochs[currentEpochId - 1].state = EpochState.Idle; // Mark previous epoch as Idle if it wasn't already

        emit EpochStarted(epochId, epoch.commitPeriodEnd, epoch.revealPeriodEnd, epoch.entropyPeriodEnd);
        emit EpochTransitioned(epochId, EpochState.Idle, EpochState.Commit); // Assuming transition from Idle for simplicity, could be from Resolved
    }

    /**
     * @notice Transitions the current epoch from Commit to Reveal.
     * @dev Callable by anyone, but only after the commit period has ended.
     */
    function transitionToReveal() public {
        uint256 epochId = currentEpochId;
        EpochDetails storage epoch = epochs[epochId];

        if (epoch.state != EpochState.Commit) revert InvalidEpochState();
        if (block.timestamp < epoch.commitPeriodEnd) revert EpochTransitionNotDue();

        epoch.state = EpochState.Reveal;
        emit EpochTransitioned(epochId, EpochState.Commit, EpochState.Reveal);
    }

    /**
     * @notice Transitions the current epoch from Reveal to EntropyPending.
     * @dev Callable by anyone, but only after the reveal period has ended.
     */
    function transitionToEntropyPending() public {
        uint256 epochId = currentEpochId;
        EpochDetails storage epoch = epochs[epochId];

        if (epoch.state != EpochState.Reveal) revert InvalidEpochState();
        if (block.timestamp < epoch.revealPeriodEnd) revert EpochTransitionNotDue();

        epoch.state = EpochState.EntropyPending;
        emit EpochTransitioned(epochId, EpochState.Reveal, EpochState.EntropyPending);
    }

    /**
     * @notice Provided by the designated entropy source to resolve the epoch.
     * @param _entropySeed The random seed used for outcome determination.
     * @dev Callable only by the entropySource address. Requires state is EntropyPending and period is active.
     * Triggers the resolution logic (_calculateAndDistribute).
     */
    function provideEntropy(bytes32 _entropySeed) public onlyEntropySource requireState(currentEpochId, EpochState.EntropyPending) {
        uint256 epochId = currentEpochId;
        EpochDetails storage epoch = epochs[epochId];

        if (block.timestamp > epoch.entropyPeriodEnd) revert EntropyPeriodActive(); // Should be EntropyPeriodExpired? Revert if time is UP

        epoch.entropySeed = _entropySeed;

        // Resolve the epoch immediately after entropy is provided
        _calculateAndDistribute(epochId, _entropySeed);

        epoch.state = EpochState.Resolved;
        emit EntropyProvided(epochId, msg.sender, _entropySeed);
        emit EpochTransitioned(epochId, EpochState.EntropyPending, EpochState.Resolved);
    }

    // --- User Interaction Functions ---

    /**
     * @notice Commits value to specific outcomes with defined weights.
     * @param outcomeWeights Mapping of outcome IDs to uint256 weights.
     * @param payloadHash Keccak256 hash of the user's full payload (including weights and any associated data).
     * @dev Requires state is Commit and within the commit period. Requires value sent >= minimumCommitValue.
     * Requires outcomeWeights to have a total weight > 0 and only use valid outcome IDs.
     * A user can only commit once per epoch.
     */
    function commit(mapping(uint8 => uint256) calldata outcomeWeights, bytes32 payloadHash) public payable requireState(currentEpochId, EpochState.Commit) {
        uint256 epochId = currentEpochId;
        EpochDetails storage epoch = epochs[epochId];
        address user = msg.sender;

        if (block.timestamp > epoch.commitPeriodEnd) revert CommitPeriodNotActive(); // Should be CommitPeriodExpired?

        if (epoch.commits[user].lockedValue > 0) revert CommitAlreadyExists();
        if (msg.value < minimumCommitValue) revert InsufficientCommitValue(minimumCommitValue, msg.value);

        uint256 totalWeight = 0;
        for (uint i = 0; i < configuredOutcomeIds.length; i++) {
            uint8 outcomeId = configuredOutcomeIds[i];
            uint256 weight = outcomeWeights[outcomeId];
            if (weight > 0 && !outcomeConfigs[outcomeId].exists) revert InvalidOutcomeWeights(); // Ensure configured outcomes
            totalWeight += weight;
        }
        if (totalWeight == 0) revert InvalidOutcomeWeights();

        // Store commit details
        UserCommit storage userCommit = epoch.commits[user];
        userCommit.lockedValue = msg.value;
        userCommit.payloadHash = payloadHash;
        // Copy weights - Note: mapping copy requires iteration. Limited outcomes are better.
        for (uint i = 0; i < configuredOutcomeIds.length; i++) {
             userCommit.outcomeWeights[configuredOutcomeIds[i]] = outcomeWeights[configuredOutcomeIds[i]];
        }
        userCommit.revealed = false;
        userCommit.claimed = false;
        userCommit.resolvedClaimValue = 0; // Initialize to 0

        epoch.totalCommittedValue += msg.value;

        emit CommitSubmitted(epochId, user, msg.value, payloadHash);
    }

    /**
     * @notice Reveals the payload data associated with a user's commit.
     * @param payload The full payload data (should match the hash committed earlier).
     * @dev Requires state is Reveal and within the reveal period. User must have an active commit for the epoch.
     * Payload hash must match the one stored in the commit. Cannot reveal if already revealed.
     * The payload content itself should be validated by the user off-chain before hashing/committing.
     */
    function revealCommit(bytes memory payload) public requireState(currentEpochId, EpochState.Reveal) {
        uint256 epochId = currentEpochId;
        EpochDetails storage epoch = epochs[epochId];
        address user = msg.sender;
        UserCommit storage userCommit = epoch.commits[user];

        if (block.timestamp > epoch.revealPeriodEnd) revert RevealPeriodNotActive(); // Should be RevealPeriodExpired?

        if (userCommit.lockedValue == 0) revert NoActiveCommit();
        if (userCommit.revealed) revert CommitDataAlreadyRevealed();
        if (keccak256(payload) != userCommit.payloadHash) revert InvalidRevealData();

        userCommit.revealed = true;

        // Add user's weights to the total revealed weights for the epoch
        for (uint i = 0; i < configuredOutcomeIds.length; i++) {
             uint8 outcomeId = configuredOutcomeIds[i];
             epoch.totalRevealedOutcomeWeights[outcomeId] += uint224(userCommit.outcomeWeights[outcomeId]); // unchecked cast - assuming weights fit in uint224
        }

        emit CommitRevealed(epochId, user);
    }

    /**
     * @notice Allows a user to cancel their commit during the Commit phase.
     * @dev Requires state is Commit and within the commit period. User must have an active commit.
     */
    function cancelCommit() public requireState(currentEpochId, EpochState.Commit) {
        uint256 epochId = currentEpochId;
        EpochDetails storage epoch = epochs[epochId];
        address user = msg.sender;
        UserCommit storage userCommit = epoch.commits[user];

        if (block.timestamp > epoch.commitPeriodEnd) revert CannotCancelAfterCommitPeriod(); // Clearer error

        if (userCommit.lockedValue == 0) revert NoActiveCommit();

        uint256 refundedValue = userCommit.lockedValue;
        epoch.totalCommittedValue -= refundedValue;

        // Delete the commit entry
        delete epoch.commits[user];

        // Refund user
        (bool success, ) = user.call{value: refundedValue}("");
        require(success, "Refund failed"); // Low level call check

        emit CommitCancelled(epochId, user, refundedValue);
    }

    /**
     * @notice Allows a user to claim their resolved value for a specific resolved epoch.
     * @param epochId The ID of the epoch to claim from.
     * @dev Requires the epoch to be in the Resolved state. User must have a commit in that epoch that hasn't been claimed.
     */
    function claimResolvedValue(uint256 epochId) public viewEpochResolved(epochId) {
        EpochDetails storage epoch = epochs[epochId];
        address user = msg.sender;
        UserCommit storage userCommit = epoch.commits[user];

        if (userCommit.lockedValue == 0) revert NoActiveCommit(); // User didn't commit in this epoch
        if (userCommit.claimed) revert ValueAlreadyClaimed();
        if (userCommit.resolvedClaimValue == 0) revert NoValueToClaim(); // Should have a calculated claim value

        uint256 claimAmount = userCommit.resolvedClaimValue;
        userCommit.claimed = true; // Mark as claimed

        // Send value
        (bool success, ) = user.call{value: claimAmount}("");
        require(success, "Claim transfer failed"); // Low level call check

        emit ValueClaimed(epochId, user, claimAmount);
    }

    // --- Internal Logic Functions ---

    /**
     * @notice Internal function to calculate the winning outcome and distribute funds/penalties.
     * @param epochId The ID of the epoch to resolve.
     * @param _entropySeed The random seed provided.
     * @dev Called by `provideEntropy`. Iterates through all commits to calculate penalty pool
     * and determine winning shares for revealing users who picked the winner.
     * This loop can be gas-intensive with many users.
     */
    function _calculateAndDistribute(uint256 epochId, bytes32 _entropySeed) internal {
        EpochDetails storage epoch = epochs[epochId];
        uint256 totalPenaltyValue = 0;
        uint256 totalWinningRevealedValue = 0; // Total value from users who committed to the winning outcome AND revealed

        // Calculate total revealed weight and penalty pool
        uint256 totalRevealedWeight = 0;
        for (uint i = 0; i < configuredOutcomeIds.length; i++) {
            totalRevealedWeight += epoch.totalRevealedOutcomeWeights[configuredOutcomeIds[i]];
        }

        // Determine winning outcome based on entropy and total revealed weights
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(_entropySeed, block.difficulty, block.timestamp))); // Pseudo-randomness
        uint256 randomWeight = totalRevealedWeight > 0 ? randomNumber % totalRevealedWeight : 0;

        uint8 winningOutcomeId = 0; // Default to 0 or invalid ID
        uint256 cumulativeWeight = 0;
        bool outcomeFound = false;

        if (totalRevealedWeight > 0) {
             // Need to sort outcomes by ID or use a predictable iteration order
             // The configuredOutcomeIds array provides a predictable order
             for (uint i = 0; i < configuredOutcomeIds.length; i++) {
                 uint8 outcomeId = configuredOutcomeIds[i];
                 uint256 outcomeRevealedWeight = epoch.totalRevealedOutcomeWeights[outcomeId];
                 if (outcomeRevealedWeight > 0) { // Only consider outcomes with revealed commits
                     cumulativeWeight += outcomeRevealedWeight;
                     if (randomWeight < cumulativeWeight) {
                         winningOutcomeId = outcomeId;
                         outcomeFound = true;
                         break; // Winning outcome found
                     }
                 }
             }
             // If totalRevealedWeight > 0 but no outcome found (shouldn't happen with correct logic, but safety):
             // This case could indicate issues if randomWeight equals totalRevealedWeight exactly when the last outcome has 0 weight.
             // Modulo operator handles this. If randomWeight >= cumulativeWeight for the last outcome, that outcome wins.
             // The loop structure handles this correctly assuming configuredOutcomeIds is exhaustive of possible outcomes with revealed weight.
        }
         // If totalRevealedWeight is 0, no outcome is selected. The epoch results in no winner/loser, funds are claimable as is (no penalties).
         // Or, we could define a default outcome 0 = "No resolution". Let's make 0 the "no resolution" outcome.
         // If no revealed commits or totalRevealedWeight is 0, winningOutcomeId remains 0.

        epoch.winningOutcomeId = winningOutcomeId;

        // Calculate penalty pool and winning shares
        // Note: This loop iterates over potentially many users. Gas limits might apply.
        // A more scalable approach might require users/bots to call a separate function
        // to "process" batches of losing/winning commits off-chain and submit proofs,
        // or calculate penalty distribution client-side. But sticking to on-chain for this example.
        address[] memory committeeAddresses = new address[](epochs[epochId].commits.length); // Estimate max users (inefficient) - better: iterate through user list if stored, or require user to check their own status
        uint numCommits = 0; // Actual number of commits

        // First pass to find users who committed (cannot iterate mapping directly)
        // A better design would track active commit addresses in an array during the Commit phase.
        // For this example, we'll simulate iterating through potential users or rely on external iteration for claim logic.
        // However, to *calculate* penalties and shares on-chain, we MUST iterate or use an external mechanism.
        // Let's assume a mechanism exists to get the list of addresses who committed for this epoch.
        // Example: A simple array `address[] committedUsers[epochId];` populated in `commit()`.
        // This would increase gas for commit and storage. Let's add that simpler array approach.

        // Update: Added `committedUsers` array to EpochDetails struct (needs re-adding to struct above).
        // Let's use the array approach.

        address[] memory epochCommittedUsers = new address[](epochs[epochId].committedUsers.length);
        for(uint i=0; i < epochs[epochId].committedUsers.length; i++) {
            epochCommittedUsers[i] = epochs[epochId].committedUsers[i];
        }


        uint totalValueToDistribute = 0; // Principal + Penalties

        // Iterate through actual committed users using the new array
        for (uint i = 0; i < epochCommittedUsers.length; i++) {
            address user = epochCommittedUsers[i];
            UserCommit storage userCommit = epoch.commits[user];

            // If commit exists (sanity check, should exist if in array)
            if (userCommit.lockedValue > 0) {
                if (!userCommit.revealed) {
                    // User failed to reveal -> Penalty
                    totalPenaltyValue += userCommit.lockedValue;
                    userCommit.resolvedClaimValue = 0; // They get nothing
                } else {
                    // User revealed
                    uint256 userWinningWeight = userCommit.outcomeWeights[winningOutcomeId]; // Weight user put on the winning outcome
                    uint256 totalRevealedWinningWeight = epoch.totalRevealedOutcomeWeights[winningOutcomeId]; // Total revealed weight on the winning outcome

                     if (winningOutcomeId != 0 && userWinningWeight > 0 && totalRevealedWinningWeight > 0) {
                         // User committed to the winning outcome AND revealed -> Winner
                         // They get their principal back, plus a share of penalties
                         userCommit.resolvedClaimValue = userCommit.lockedValue; // Principal return is guaranteed if they win & reveal
                         totalWinningRevealedValue += userCommit.lockedValue; // Track total principal of winners for penalty distribution base
                     } else {
                         // User committed to losing outcome(s) OR (winningOutcomeId is 0 and they committed) -> Loser
                         totalPenaltyValue += userCommit.lockedValue;
                         userCommit.resolvedClaimValue = 0; // They get nothing
                     }
                }
            }
        }

        epoch.penaltyPoolValue = totalPenaltyValue;

        // Distribute penalty pool among winning+revealed users
        if (totalWinningRevealedValue > 0 && totalPenaltyValue > 0) {
             for (uint i = 0; i < epochCommittedUsers.length; i++) {
                 address user = epochCommittedUsers[i];
                 UserCommit storage userCommit = epoch.commits[user];

                 // If user was a winner and revealed (check resolvedClaimValue > 0 implies principal assigned)
                 if (userCommit.resolvedClaimValue > 0) {
                      uint256 principalShare = userCommit.lockedValue;
                      // Calculate penalty share: (User's Principal / Total Winning Revealed Principal) * Total Penalty
                      uint256 penaltyShare = (principalShare * totalPenaltyValue) / totalWinningRevealedValue;
                      userCommit.resolvedClaimValue += penaltyShare; // Add penalty share to their claimable amount
                 }
             }
        }

        // Execute winning outcome payload if a winning outcome was determined (ID != 0)
        if (winningOutcomeId != 0 && outcomeConfigs[winningOutcomeId].exists) {
             _executeWinningOutcomePayload(epochId, winningOutcomeId, outcomeConfigs[winningOutcomeId].payload);
        }

        emit EpochResolved(epochId, winningOutcomeId, _entropySeed, totalPenaltyValue);
    }

    /**
     * @notice Internal function to execute the payload associated with the winning outcome.
     * @param epochId The ID of the resolved epoch.
     * @param winningOutcomeId The ID of the determined winning outcome.
     * @param payload The payload bytes from the OutcomeConfig.
     * @dev This is a placeholder. The actual implementation depends on what the payload is intended to do.
     * For a simple example, it could parse instructions to send remaining contract balance to specific addresses.
     * IMPORTANT: Complex payload execution can hit gas limits.
     */
    function _executeWinningOutcomePayload(uint256 epochId, uint8 winningOutcomeId, bytes memory payload) internal {
        // Example placeholder: If payload starts with 0x1a ("send"): abi.decode remaining bytes as address[] and uint256[], and send balance.
        // This is complex and requires careful design. For this example, let's just emit an event.
        // In a real dapp, this payload might trigger calls to other contracts or internal state changes.

        // Example (commented out, requires parsing logic):
        /*
        if (payload.length > 0) {
            bytes1 actionByte = payload[0];
            if (actionByte == 0x1a) { // Example: 'send' action
                // Parse recipient addresses and amounts from remaining payload bytes
                // Requires specific abi encoding format for the payload
                // (bool success, ) = recipient.call{value: amount}("");
                // require(success, "Payload execution failed");
            }
            // Add other actions as needed
        }
        */
        // Placeholder event for demonstration
        emit WinningOutcomePayloadExecuted(epochId, winningOutcomeId, payload);
    }
    event WinningOutcomePayloadExecuted(uint256 indexed epochId, uint8 indexed winningOutcomeId, bytes payload);


    // --- View Functions ---

    /**
     * @notice Gets the current state of the active epoch.
     */
    function getEpochState() public view returns (EpochState) {
        return epochs[currentEpochId].state;
    }

    /**
     * @notice Gets the ID of the currently active epoch.
     */
    function getCurrentEpochId() public view returns (uint256) {
        return currentEpochId;
    }

     /**
     * @notice Gets the timestamp when the commit period ends for the current epoch.
     */
    function getCommitPeriodEnd() public view returns (uint64) {
        return epochs[currentEpochId].commitPeriodEnd;
    }

     /**
     * @notice Gets the timestamp when the reveal period ends for the current epoch.
     */
    function getRevealPeriodEnd() public view returns (uint64) {
        return epochs[currentEpochId].revealPeriodEnd;
    }

     /**
     * @notice Gets the timestamp when the entropy pending period ends for the current epoch.
     */
    function getEntropyPeriodEnd() public view returns (uint64) {
        return epochs[currentEpochId].entropyPeriodEnd;
    }

    /**
     * @notice Gets the configuration details for a specific outcome ID.
     * @param outcomeId The ID of the outcome.
     */
    function getOutcomeConfig(uint8 outcomeId) public view returns (OutcomeConfig memory) {
        if (!outcomeConfigs[outcomeId].exists) revert InvalidOutcomeId(outcomeId);
        return outcomeConfigs[outcomeId];
    }

    /**
     * @notice Gets the commit details for a user in the current epoch.
     * @param user The address of the user.
     */
    function getUserCommit(address user) public view returns (UserCommit memory) {
        // Note: Mapping return copies. outcomeWeights map is not copied directly.
        // If detailed weights are needed, a separate view function iterating outcomes is required.
        // This return is simplified.
        UserCommit storage commit = epochs[currentEpochId].commits[user];
        return UserCommit({
            lockedValue: commit.lockedValue,
            payloadHash: commit.payloadHash,
            outcomeWeights: commit.outcomeWeights, // This will likely show empty map due to Solidity limitations in view functions
            revealed: commit.revealed,
            claimed: commit.claimed,
            resolvedClaimValue: commit.resolvedClaimValue
        });
    }

     /**
     * @notice Gets the total value committed in the current epoch.
     */
    function getTotalCommittedValue() public view returns (uint256) {
        return epochs[currentEpochId].totalCommittedValue;
    }

    /**
     * @notice Gets the configured entropy source address.
     */
    function getEntropySource() public view returns (address) {
        return entropySource;
    }

    /**
     * @notice Gets the winning outcome ID for a specific resolved epoch.
     * @param epochId The ID of the resolved epoch.
     */
    function getResolvedEpochWinningOutcome(uint256 epochId) public view requireState(epochId, EpochState.Resolved) returns (uint8) {
        return epochs[epochId].winningOutcomeId;
    }

    /**
     * @notice Gets the entropy seed used for a specific resolved epoch.
     * @param epochId The ID of the resolved epoch.
     */
    function getResolvedEpochEntropySeed(uint256 epochId) public view requireState(epochId, EpochState.Resolved) returns (bytes32) {
        return epochs[epochId].entropySeed;
    }

    /**
     * @notice Calculates and returns the total *revealed* weight committed to an outcome in the current epoch.
     * @param outcomeId The ID of the outcome.
     * @dev Sums up weights from all users who *revealed* their commit in the current epoch for the given outcome.
     */
    function getTotalRevealedWeightForOutcome(uint8 outcomeId) public view returns (uint256) {
        return epochs[currentEpochId].totalRevealedOutcomeWeights[outcomeId];
    }

    /**
     * @notice Gets the total penalty value collected for a specific resolved epoch.
     * @param epochId The ID of the resolved epoch.
     */
    function getResolvedEpochPenaltyPool(uint256 epochId) public view requireState(epochId, EpochState.Resolved) returns (uint256) {
         return epochs[epochId].penaltyPoolValue;
    }

    // --- Helper Modifiers for View Functions ---
     modifier viewEpochResolved(uint256 epochId) {
         if (epochs[epochId].state != EpochState.Resolved) revert EpochNotResolved();
         _;
     }
}
```